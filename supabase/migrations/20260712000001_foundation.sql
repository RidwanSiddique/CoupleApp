-- Sakīnah — Phase 0 foundation schema
-- users, couples, pairing_invites, prayer_logs, signal_key_bundles
-- + RLS + pairing RPCs

create extension if not exists "pgcrypto";

------------------------------------------------------------------
-- users
------------------------------------------------------------------
create table public.users (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text        not null default '',
  timezone      text        not null default 'UTC',
  madhhab       text        not null default 'shafi'
                check (madhhab in ('shafi', 'hanafi')),
  calc_method   text        not null default 'muslim_world_league',
  latitude      double precision,
  longitude     double precision,
  push_token    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

------------------------------------------------------------------
-- signal_key_bundles: public halves of each device's Signal keys
------------------------------------------------------------------
create table public.signal_key_bundles (
  user_id            uuid not null references public.users(id) on delete cascade,
  device_id          text not null,
  registration_id    integer not null,
  identity_pub       bytea not null,
  signed_prekey_id   integer not null,
  signed_prekey_pub  bytea not null,
  signed_prekey_sig  bytea not null,
  one_time_prekeys   jsonb not null default '[]'::jsonb,
  updated_at         timestamptz not null default now(),
  primary key (user_id, device_id)
);

------------------------------------------------------------------
-- couples: exactly two members, normalized order
------------------------------------------------------------------
create table public.couples (
  id                uuid primary key default gen_random_uuid(),
  member_a          uuid not null references public.users(id) on delete cascade,
  member_b          uuid not null references public.users(id) on delete cascade,
  status            text not null default 'active'
                    check (status in ('active', 'archived')),
  anniversary_greg  date,
  anniversary_hijri text,
  long_distance     boolean not null default false,
  created_at        timestamptz not null default now(),
  check (member_a <> member_b),
  check (member_a < member_b),
  unique (member_a, member_b)
);

create index couples_member_a_idx on public.couples(member_a);
create index couples_member_b_idx on public.couples(member_b);

------------------------------------------------------------------
-- pairing_invites: 6-char code, single-use, 10-min TTL
------------------------------------------------------------------
create table public.pairing_invites (
  code         text primary key,
  inviter_id   uuid not null references public.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null,
  consumed_at  timestamptz,
  consumed_by  uuid references public.users(id) on delete set null
);

create index pairing_invites_inviter_idx on public.pairing_invites(inviter_id);

------------------------------------------------------------------
-- prayer_logs: prepared for Phase 1, RLS installed now
------------------------------------------------------------------
create table public.prayer_logs (
  id           uuid primary key default gen_random_uuid(),
  couple_id    uuid not null references public.couples(id) on delete cascade,
  user_id      uuid not null references public.users(id) on delete cascade,
  date         date not null,
  prayer       text not null
                check (prayer in ('fajr','dhuhr','asr','maghrib','isha')),
  status       text not null default 'prayed'
                check (status in ('prayed','missed','skipped')),
  time_logged  timestamptz not null default now(),
  unique (couple_id, user_id, date, prayer)
);

------------------------------------------------------------------
-- Helper: is caller in this couple?
------------------------------------------------------------------
create or replace function public.is_couple_member(p_couple_id uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.couples c
    where c.id = p_couple_id
      and auth.uid() in (c.member_a, c.member_b)
  );
$$;

create or replace function public.current_couple()
returns uuid
language sql stable security definer
set search_path = public
as $$
  select id from public.couples
   where auth.uid() in (member_a, member_b)
     and status = 'active'
   limit 1;
$$;

------------------------------------------------------------------
-- Row-level security
------------------------------------------------------------------
alter table public.users             enable row level security;
alter table public.signal_key_bundles enable row level security;
alter table public.couples           enable row level security;
alter table public.pairing_invites   enable row level security;
alter table public.prayer_logs       enable row level security;

-- users: read self, or spouse. update self only.
create policy users_read_self_or_spouse on public.users
  for select using (
    id = auth.uid()
    or exists (
      select 1 from public.couples c
      where auth.uid() in (c.member_a, c.member_b)
        and public.users.id in (c.member_a, c.member_b)
    )
  );

create policy users_upsert_self on public.users
  for insert with check (id = auth.uid());

create policy users_update_self on public.users
  for update using (id = auth.uid()) with check (id = auth.uid());

-- signal_key_bundles: read self or spouse (X3DH needs partner bundle)
create policy skb_read_self_or_spouse on public.signal_key_bundles
  for select using (
    user_id = auth.uid()
    or exists (
      select 1 from public.couples c
      where auth.uid() in (c.member_a, c.member_b)
        and public.signal_key_bundles.user_id in (c.member_a, c.member_b)
    )
  );

create policy skb_write_self on public.signal_key_bundles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- couples: read/update as member. Insert only via RPC.
create policy couples_read_members on public.couples
  for select using (auth.uid() in (member_a, member_b));

create policy couples_update_members on public.couples
  for update using (auth.uid() in (member_a, member_b))
              with check (auth.uid() in (member_a, member_b));

-- pairing_invites: only inviter can select their own invites directly.
-- Acceptance is via SECURITY DEFINER RPC so the joining user doesn't need row access.
create policy invites_read_own on public.pairing_invites
  for select using (inviter_id = auth.uid());

-- prayer_logs: full CRUD for couple members only
create policy prayer_logs_couple on public.prayer_logs
  for all using (public.is_couple_member(couple_id))
          with check (public.is_couple_member(couple_id) and user_id = auth.uid());

------------------------------------------------------------------
-- Pairing RPCs
------------------------------------------------------------------

-- Generate a 6-char code from Crockford's base32 minus ambiguous chars.
-- Alphabet excludes I, L, O, U to avoid confusion.
create or replace function public.generate_invite_code()
returns text
language plpgsql volatile
as $$
declare
  alphabet constant text := 'ABCDEFGHJKMNPQRSTVWXYZ23456789';
  result   text := '';
  i        integer;
begin
  for i in 1..6 loop
    result := result || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  end loop;
  return result;
end;
$$;

create or replace function public.create_pairing_invite()
returns table(code text, expires_at timestamptz)
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_code   text;
  v_uid    uuid := auth.uid();
  v_exists boolean;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  -- caller must not already be in a couple
  if exists (
    select 1 from public.couples
     where v_uid in (member_a, member_b)
       and status = 'active'
  ) then
    raise exception 'already_paired';
  end if;

  -- invalidate any of caller's still-active invites
  update public.pairing_invites p
     set expires_at = now()
   where p.inviter_id = v_uid
     and p.consumed_at is null
     and p.expires_at > now();

  -- retry until we find a unique code (astronomically unlikely to loop more than once)
  loop
    v_code := public.generate_invite_code();
    select true into v_exists
      from public.pairing_invites p where p.code = v_code;
    exit when v_exists is null;
    v_exists := null;
  end loop;

  insert into public.pairing_invites (code, inviter_id, expires_at)
       values (v_code, v_uid, now() + interval '10 minutes');

  code := v_code;
  expires_at := now() + interval '10 minutes';
  return next;
end;
$$;

create or replace function public.accept_pairing_invite(p_code text)
returns public.couples
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_uid     uuid := auth.uid();
  v_invite  public.pairing_invites%rowtype;
  v_a       uuid;
  v_b       uuid;
  v_couple  public.couples%rowtype;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  select * into v_invite
    from public.pairing_invites
   where code = upper(trim(p_code))
   for update;

  if not found then
    raise exception 'invite_not_found';
  end if;

  if v_invite.consumed_at is not null then
    raise exception 'invite_already_used';
  end if;

  if v_invite.expires_at < now() then
    raise exception 'invite_expired';
  end if;

  if v_invite.inviter_id = v_uid then
    raise exception 'cannot_pair_with_self';
  end if;

  if exists (
    select 1 from public.couples
     where v_uid in (member_a, member_b) and status = 'active'
  ) then
    raise exception 'already_paired';
  end if;

  if exists (
    select 1 from public.couples
     where v_invite.inviter_id in (member_a, member_b) and status = 'active'
  ) then
    raise exception 'inviter_already_paired';
  end if;

  -- normalize member order
  if v_invite.inviter_id < v_uid then
    v_a := v_invite.inviter_id;
    v_b := v_uid;
  else
    v_a := v_uid;
    v_b := v_invite.inviter_id;
  end if;

  update public.pairing_invites
     set consumed_at = now(), consumed_by = v_uid
   where code = v_invite.code;

  insert into public.couples (member_a, member_b)
       values (v_a, v_b)
    returning * into v_couple;

  return v_couple;
end;
$$;

------------------------------------------------------------------
-- Auto-create public.users row when auth.users row is created
------------------------------------------------------------------
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.users (id, display_name)
       values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''))
   on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

------------------------------------------------------------------
-- Grants: RLS enforces row-level access, but Postgres also requires
-- table-level GRANTs before it will consider policies. Give the
-- `authenticated` role CRUD on couple-scoped tables; RLS narrows the rows.
------------------------------------------------------------------
grant usage on schema public to authenticated;

grant select, insert, update on public.users              to authenticated;
grant select, insert, update, delete on public.signal_key_bundles to authenticated;
grant select, update on public.couples                    to authenticated;
grant select on public.pairing_invites                    to authenticated;
grant select, insert, update, delete on public.prayer_logs to authenticated;

-- RPCs
grant execute on function public.create_pairing_invite() to authenticated;
grant execute on function public.accept_pairing_invite(text) to authenticated;
grant execute on function public.is_couple_member(uuid) to authenticated;
grant execute on function public.current_couple() to authenticated;
grant execute on function public.generate_invite_code() to authenticated;
