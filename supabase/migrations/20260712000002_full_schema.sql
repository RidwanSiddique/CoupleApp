-- Sakīnah — Phase 1 through Phase 5 full schema
--
-- Cloud-migration-ready. Every couple-scoped table:
--   • has couple_id fk
--   • enables RLS with is_couple_member(couple_id)
--   • grants CRUD to `authenticated` (RLS narrows rows)
--   • has an index on couple_id (+ created_at where useful)
--
-- Auxiliary content tables (verses, hadith, duas seed) are world-readable
-- since they contain no user data.

------------------------------------------------------------------
-- Section 1 — Phase 1: chat, feed, verses/duas/hadith, daily prompts
------------------------------------------------------------------

-- 1.1 Conversations & messages (E2E, server holds ciphertext only)

create table public.conversations (
  id                uuid primary key default gen_random_uuid(),
  couple_id         uuid not null unique references public.couples(id) on delete cascade,
  created_at        timestamptz not null default now(),
  last_message_at   timestamptz
);

create table public.messages (
  id                uuid primary key default gen_random_uuid(),
  conversation_id   uuid not null references public.conversations(id) on delete cascade,
  couple_id         uuid not null references public.couples(id) on delete cascade,
  sender_id         uuid not null references public.users(id) on delete cascade,
  recipient_id      uuid not null references public.users(id) on delete cascade,
  -- Signal Double Ratchet output: `type` = 1 (pre-key) or 3 (message) per libsignal
  cipher_type       smallint not null default 3,
  ciphertext        bytea not null,
  device_id         text not null,
  created_at        timestamptz not null default now(),
  delivered_at      timestamptz,
  read_at           timestamptz,
  -- Optional: media attachments stored separately in Storage
  attachment_url    text,
  attachment_mime   text,
  attachment_bytes  bigint,
  ephemeral_until   timestamptz,
  reply_to          uuid references public.messages(id) on delete set null
);
create index messages_couple_created_idx on public.messages(couple_id, created_at desc);
create index messages_conversation_idx on public.messages(conversation_id, created_at desc);

-- 1.2 Message reactions (small ciphertext blob per reaction)
create table public.message_reactions (
  message_id  uuid not null references public.messages(id) on delete cascade,
  user_id     uuid not null references public.users(id) on delete cascade,
  reaction    text not null, -- 'alhamdulillah' | 'jazakallah' | 'heart' | emoji
  couple_id   uuid not null references public.couples(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (message_id, user_id, reaction)
);
create index message_reactions_couple_idx on public.message_reactions(couple_id);

-- 1.3 Shared "Our Wall" feed
create table public.feed_items (
  id           uuid primary key default gen_random_uuid(),
  couple_id    uuid not null references public.couples(id) on delete cascade,
  added_by     uuid not null references public.users(id) on delete cascade,
  url          text,
  title        text,
  description  text,
  image_url    text,
  source       text,       -- 'instagram' | 'youtube' | 'tiktok' | 'article' | 'photo' | 'note'
  media_url    text,       -- for uploaded photos/videos in Storage
  media_mime   text,
  collection   text,       -- 'recipes' | 'places' | 'home' | 'funny' | 'deen' | null
  note         text,
  is_pinned    boolean not null default false,
  created_at   timestamptz not null default now()
);
create index feed_items_couple_created_idx on public.feed_items(couple_id, created_at desc);
create index feed_items_couple_collection_idx on public.feed_items(couple_id, collection);

create table public.feed_reactions (
  item_id    uuid not null references public.feed_items(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  reaction   text not null,
  couple_id  uuid not null references public.couples(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (item_id, user_id, reaction)
);
create index feed_reactions_couple_idx on public.feed_reactions(couple_id);

create table public.feed_comments (
  id          uuid primary key default gen_random_uuid(),
  item_id     uuid not null references public.feed_items(id) on delete cascade,
  couple_id   uuid not null references public.couples(id) on delete cascade,
  author_id   uuid not null references public.users(id) on delete cascade,
  body        text not null,
  created_at  timestamptz not null default now()
);
create index feed_comments_item_idx on public.feed_comments(item_id, created_at);

-- 1.4 Seed content library (world-readable, admin-writable)
create table public.verses (
  id               uuid primary key default gen_random_uuid(),
  surah_number     integer not null,
  ayah_number      integer not null,
  surah_name       text not null,
  arabic_text      text not null,
  translation_en   text not null,
  translation_ur   text,
  translation_ar   text,
  transliteration  text,
  reference        text not null, -- e.g. "Quran 30:21"
  theme_tags       text[] not null default '{}',
  unique (surah_number, ayah_number)
);
create index verses_theme_gin on public.verses using gin (theme_tags);

create table public.hadiths (
  id             uuid primary key default gen_random_uuid(),
  arabic_text    text,
  translation    text not null,
  narrator       text,
  source         text not null, -- 'Bukhari' | 'Muslim' | 'Tirmidhi' | ...
  reference      text not null, -- e.g. "Sahih Muslim 1467"
  grading        text,          -- 'sahih' | 'hasan' | ...
  theme_tags     text[] not null default '{}'
);
create index hadiths_theme_gin on public.hadiths using gin (theme_tags);

create table public.duas_library (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  arabic_text    text not null,
  transliteration text,
  translation    text not null,
  reference      text,
  category       text -- 'morning' | 'evening' | 'travel' | 'marriage' | ...
);

-- 1.5 Daily prompts (question of day)
create table public.daily_questions (
  id          uuid primary key default gen_random_uuid(),
  question    text not null,
  category    text, -- 'playful' | 'reflective' | 'future' | 'deen'
  language    text not null default 'en'
);

-- 1.6 Verse/Hadith/Question-of-day pointers per couple/day
create table public.daily_content (
  couple_id       uuid not null references public.couples(id) on delete cascade,
  date            date not null,
  verse_id        uuid references public.verses(id) on delete set null,
  hadith_id       uuid references public.hadiths(id) on delete set null,
  question_id     uuid references public.daily_questions(id) on delete set null,
  primary key (couple_id, date)
);

-- 1.7 User-authored duas (shared list per couple, plus private)
create table public.duas (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  author_id      uuid not null references public.users(id) on delete cascade,
  title          text not null,
  body           text,
  visibility     text not null default 'shared' check (visibility in ('private','shared')),
  is_answered    boolean not null default false,
  answered_at    timestamptz,
  answered_note  text,
  created_at     timestamptz not null default now()
);
create index duas_couple_idx on public.duas(couple_id, created_at desc);

-- 1.8 Gratitude notes (private until revealed)
create table public.gratitude_notes (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  author_id      uuid not null references public.users(id) on delete cascade,
  body           text not null,
  reveal_to_spouse boolean not null default false,
  revealed_at    timestamptz,
  created_at     timestamptz not null default now()
);
create index gratitude_couple_author_idx on public.gratitude_notes(couple_id, author_id, created_at desc);

-- 1.9 Question-of-day answers (each spouse independently)
create table public.question_answers (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  question_id    uuid not null references public.daily_questions(id) on delete cascade,
  author_id      uuid not null references public.users(id) on delete cascade,
  answer         text not null,
  created_at     timestamptz not null default now(),
  unique (couple_id, question_id, author_id)
);
create index question_answers_couple_idx on public.question_answers(couple_id, created_at desc);

-- 1.10 Shared calendar events (Hijri + Gregorian)
create table public.calendar_events (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  created_by     uuid not null references public.users(id) on delete cascade,
  title          text not null,
  description    text,
  starts_at      timestamptz not null,
  ends_at        timestamptz,
  all_day        boolean not null default false,
  recurrence     text, -- ical RRULE
  hijri_anchor   text, -- Hijri "YYYY-MM-DD" for Islamic-calendar anchored events
  kind           text not null default 'event' check (kind in ('event','anniversary','birthday','islamic')),
  reminder_offsets integer[] not null default '{}', -- minutes before
  created_at     timestamptz not null default now()
);
create index calendar_couple_starts_idx on public.calendar_events(couple_id, starts_at);

------------------------------------------------------------------
-- Section 2 — Phase 2: Quran, Ramadan, dhikr, sadaqah, weekly check-in
------------------------------------------------------------------

create table public.quran_reading_plans (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null unique references public.couples(id) on delete cascade,
  plan_type      text not null default 'juz_a_day' check (plan_type in ('juz_a_day','page_a_day','hifdh')),
  target_surah   integer,   -- for hifdh
  started_at     date not null default current_date,
  active         boolean not null default true
);

create table public.quran_progress (
  id             uuid primary key default gen_random_uuid(),
  plan_id        uuid not null references public.quran_reading_plans(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  date           date not null,
  juz            integer,
  page_from      integer,
  page_to        integer,
  ayah_notes     jsonb not null default '[]'::jsonb, -- [{surah, ayah, note}]
  created_at     timestamptz not null default now(),
  unique (plan_id, user_id, date)
);
create index quran_progress_couple_idx on public.quran_progress(couple_id, date desc);

create table public.hifdh_recitations (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  surah          integer not null,
  ayah_from      integer not null,
  ayah_to        integer not null,
  audio_url      text not null, -- Storage URL
  confirmed_at   timestamptz,
  confirmed_by   uuid references public.users(id) on delete set null,
  created_at     timestamptz not null default now()
);

create table public.ramadan_logs (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  date           date not null,
  fasted         boolean not null default true,
  suhoor_at      timestamptz,
  iftar_at       timestamptz,
  taraweeh_rakat integer,
  qiyam_rakat    integer,
  note           text,
  unique (couple_id, user_id, date)
);
create index ramadan_couple_date_idx on public.ramadan_logs(couple_id, date);

create table public.ramadan_goals (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  year_hijri     integer not null,
  title          text not null,
  description    text,
  target         integer,
  progress       integer not null default 0,
  created_at     timestamptz not null default now()
);

create table public.dhikr_counters (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null, -- 'Salawat', 'SubhanAllah', ...
  arabic_text    text,
  target         integer not null,
  period         text not null default 'weekly' check (period in ('daily','weekly','monthly','once')),
  starts_at      timestamptz not null default now(),
  ends_at        timestamptz,
  created_at     timestamptz not null default now()
);

create table public.dhikr_contributions (
  id             uuid primary key default gen_random_uuid(),
  counter_id     uuid not null references public.dhikr_counters(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  count          integer not null check (count > 0),
  logged_at      timestamptz not null default now()
);
create index dhikr_contrib_counter_idx on public.dhikr_contributions(counter_id, logged_at);

create table public.sadaqah_entries (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  amount_minor   integer not null, -- amount * 100 in the currency's minor unit
  currency       text not null default 'USD',
  cause          text,             -- 'masjid' | 'family' | 'orphan' | ...
  note           text,
  is_rollup      boolean not null default false, -- rounded up transaction change
  occurred_on    date not null default current_date,
  created_at     timestamptz not null default now()
);
create index sadaqah_couple_date_idx on public.sadaqah_entries(couple_id, occurred_on desc);

create table public.weekly_checkins (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  week_starting  date not null,
  answers        jsonb not null default '{}'::jsonb,
  completed_at   timestamptz,
  unique (couple_id, week_starting)
);

create table public.love_language_profiles (
  user_id        uuid not null references public.users(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  scores         jsonb not null default '{}'::jsonb, -- {"words":42, "acts":18, ...}
  primary_lang   text,
  updated_at     timestamptz not null default now(),
  primary key (user_id, couple_id)
);

------------------------------------------------------------------
-- Section 3 — Phase 3: reunion, memories, watch-together, future letters, conflict
------------------------------------------------------------------

create table public.reunion_countdowns (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null default 'Reunion',
  target_date    date not null,
  location       text,
  fund_target_minor integer,
  fund_current_minor integer not null default 0,
  currency       text not null default 'USD',
  created_at     timestamptz not null default now()
);

create table public.memory_items (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  added_by       uuid not null references public.users(id) on delete cascade,
  taken_at       timestamptz,
  caption        text,
  media_url      text not null,
  media_mime     text,
  location       text,
  created_at     timestamptz not null default now()
);
create index memory_couple_taken_idx on public.memory_items(couple_id, taken_at desc);

create table public.watch_together_sessions (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  started_by     uuid not null references public.users(id) on delete cascade,
  media_type     text not null, -- 'youtube' | 'quran_audio' | 'lecture'
  media_ref      text not null,
  position_seconds numeric not null default 0,
  is_playing     boolean not null default false,
  last_sync_at   timestamptz not null default now(),
  created_at     timestamptz not null default now()
);

create table public.future_letters (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  author_id      uuid not null references public.users(id) on delete cascade,
  recipient_id   uuid references public.users(id) on delete set null, -- null = both
  body_ciphertext bytea not null,          -- E2E, opened client-side on unlock day
  unlock_at      timestamptz not null,
  unlocked_at    timestamptz,
  created_at     timestamptz not null default now()
);
create index future_letters_couple_unlock_idx on public.future_letters(couple_id, unlock_at);

create table public.conflict_logs (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  author_id      uuid not null references public.users(id) on delete cascade,
  stage          text not null default 'pause' check (stage in ('pause','feelings','forgiveness','step')),
  feelings       text,
  dua_made       boolean not null default false,
  agreed_step    text,
  reconciled_at  timestamptz,
  created_at     timestamptz not null default now()
);

create table public.love_map_quizzes (
  id             uuid primary key default gen_random_uuid(),
  question       text not null,
  category       text
);

create table public.love_map_answers (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  quiz_id        uuid not null references public.love_map_quizzes(id) on delete cascade,
  guesser_id     uuid not null references public.users(id) on delete cascade,
  guess          text not null,
  is_correct     boolean,
  played_at      timestamptz not null default now()
);

------------------------------------------------------------------
-- Section 4 — Phase 4: household, budget, meals, family, cycle, hajj
------------------------------------------------------------------

create table public.budget_categories (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  name           text not null,
  kind           text not null default 'expense' check (kind in ('expense','saving','zakat','sadaqah')),
  monthly_limit_minor integer,
  currency       text not null default 'USD'
);

create table public.budget_entries (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  category_id    uuid references public.budget_categories(id) on delete set null,
  amount_minor   integer not null,
  currency       text not null default 'USD',
  note           text,
  occurred_on    date not null default current_date,
  created_at     timestamptz not null default now()
);
create index budget_entries_couple_date_idx on public.budget_entries(couple_id, occurred_on desc);

create table public.savings_goals (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null,
  target_minor   integer not null,
  current_minor  integer not null default 0,
  currency       text not null default 'USD',
  due_at         date,
  created_at     timestamptz not null default now()
);

create table public.zakat_calculations (
  id                     uuid primary key default gen_random_uuid(),
  couple_id              uuid not null references public.couples(id) on delete cascade,
  as_of                  date not null,
  cash_minor             integer not null default 0,
  gold_grams             numeric not null default 0,
  silver_grams           numeric not null default 0,
  investments_minor      integer not null default 0,
  debts_owed_minor       integer not null default 0,
  nisab_currency         text not null default 'USD',
  nisab_minor            integer,
  zakat_due_minor        integer,
  paid_at                timestamptz,
  created_at             timestamptz not null default now()
);

create table public.meal_plans (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  week_starting  date not null,
  slots          jsonb not null default '{}'::jsonb, -- {"mon_dinner": "biryani", ...}
  unique (couple_id, week_starting)
);

create table public.recipes (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null,
  source_url     text,
  ingredients    jsonb not null default '[]'::jsonb,
  steps          jsonb not null default '[]'::jsonb,
  halal_notes    text,
  created_at     timestamptz not null default now()
);

create table public.grocery_lists (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null default 'Groceries',
  items          jsonb not null default '[]'::jsonb, -- [{name, qty, checked}]
  updated_at     timestamptz not null default now()
);

create table public.family_contacts (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  full_name      text not null,
  relation       text,       -- 'father' | 'mother' | 'in-law' | 'sibling' | ...
  side           text check (side in ('mine','spouse','both')),
  birthday_greg  date,
  birthday_hijri text,
  phone          text,
  last_contacted date,
  reminder_days  integer not null default 14
);

create table public.cycle_records (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  started_on     date not null,
  ended_on       date,
  visibility     text not null default 'private' check (visibility in ('private','shared')),
  note           text,
  unique (user_id, started_on)
);

create table public.travel_itineraries (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null,
  destination    text,
  starts_on      date,
  ends_on        date,
  is_hajj        boolean not null default false,
  is_umrah       boolean not null default false,
  itinerary_json jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);

create table public.packing_lists (
  id             uuid primary key default gen_random_uuid(),
  itinerary_id   uuid references public.travel_itineraries(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null default 'Packing',
  items          jsonb not null default '[]'::jsonb,
  updated_at     timestamptz not null default now()
);

------------------------------------------------------------------
-- Section 5 — Phase 3-4 crosscutting: goals (niyyah), mood, appreciation jar
------------------------------------------------------------------

create table public.shared_goals (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  title          text not null,       -- 'Hajj 2028', 'Hifdh of Al-Mulk', ...
  description    text,
  category       text,                -- 'deen' | 'financial' | 'family' | 'personal'
  target_date    date,
  progress_pct   numeric not null default 0,
  status         text not null default 'active' check (status in ('active','achieved','archived')),
  attached_duas  uuid[],
  created_at     timestamptz not null default now()
);

create table public.mood_checkins (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.users(id) on delete cascade,
  couple_id      uuid not null references public.couples(id) on delete cascade,
  mood           smallint not null check (mood between 1 and 5),
  note           text,
  visibility     text not null default 'shared' check (visibility in ('private','shared')),
  created_at     timestamptz not null default now()
);
create index mood_couple_created_idx on public.mood_checkins(couple_id, created_at desc);

create table public.appreciation_jar (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  gratitude_id   uuid references public.gratitude_notes(id) on delete set null,
  note           text,
  created_at     timestamptz not null default now()
);

------------------------------------------------------------------
-- Section 6 — Phase 5: presence, taps, learning
------------------------------------------------------------------

create table public.presence_taps (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  sender_id      uuid not null references public.users(id) on delete cascade,
  tap_type       text not null default 'heartbeat' check (tap_type in ('heartbeat','dua','thinking','wake_for_fajr')),
  created_at     timestamptz not null default now()
);
create index taps_couple_created_idx on public.presence_taps(couple_id, created_at desc);

create table public.learning_lessons (
  id             uuid primary key default gen_random_uuid(),
  title          text not null,
  category       text,
  language       text not null default 'en',
  body           text not null,
  arabic_body    text,
  reference      text
);

create table public.learning_progress (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  user_id        uuid not null references public.users(id) on delete cascade,
  lesson_id      uuid not null references public.learning_lessons(id) on delete cascade,
  answers        jsonb not null default '{}'::jsonb,
  completed_at   timestamptz,
  unique (couple_id, user_id, lesson_id)
);

create table public.trust_vault_items (
  id             uuid primary key default gen_random_uuid(),
  couple_id      uuid not null references public.couples(id) on delete cascade,
  added_by       uuid not null references public.users(id) on delete cascade,
  title          text not null,
  kind           text,                  -- 'document' | 'note' | 'contact' | 'password'
  ciphertext     bytea not null,        -- E2E
  file_url       text,                  -- if file, encrypted before upload
  created_at     timestamptz not null default now()
);

------------------------------------------------------------------
-- Section 7 — Enable RLS + policies for every couple-scoped table
------------------------------------------------------------------

do $$
declare
  t text;
  scoped_tables text[] := array[
    'conversations','messages','message_reactions',
    'feed_items','feed_reactions','feed_comments',
    'daily_content','duas','gratitude_notes','question_answers','calendar_events',
    'quran_reading_plans','quran_progress','hifdh_recitations',
    'ramadan_logs','ramadan_goals',
    'dhikr_counters','dhikr_contributions',
    'sadaqah_entries','weekly_checkins','love_language_profiles',
    'reunion_countdowns','memory_items','watch_together_sessions',
    'future_letters','conflict_logs','love_map_answers',
    'budget_categories','budget_entries','savings_goals','zakat_calculations',
    'meal_plans','recipes','grocery_lists','family_contacts',
    'cycle_records','travel_itineraries','packing_lists',
    'shared_goals','mood_checkins','appreciation_jar',
    'presence_taps','learning_progress','trust_vault_items'
  ];
begin
  foreach t in array scoped_tables loop
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy %I on public.%I for all using (public.is_couple_member(couple_id)) with check (public.is_couple_member(couple_id))',
      t || '_couple_rls', t
    );
    execute format(
      'grant select, insert, update, delete on public.%I to authenticated', t
    );
  end loop;
end $$;

-- World-readable content library
alter table public.verses          enable row level security;
alter table public.hadiths         enable row level security;
alter table public.duas_library    enable row level security;
alter table public.daily_questions enable row level security;
alter table public.love_map_quizzes enable row level security;
alter table public.learning_lessons enable row level security;

create policy verses_read           on public.verses           for select using (true);
create policy hadiths_read          on public.hadiths          for select using (true);
create policy duas_library_read     on public.duas_library     for select using (true);
create policy daily_questions_read  on public.daily_questions  for select using (true);
create policy love_map_quizzes_read on public.love_map_quizzes for select using (true);
create policy learning_lessons_read on public.learning_lessons for select using (true);

grant select on public.verses           to authenticated;
grant select on public.hadiths          to authenticated;
grant select on public.duas_library     to authenticated;
grant select on public.daily_questions  to authenticated;
grant select on public.love_map_quizzes to authenticated;
grant select on public.learning_lessons to authenticated;

------------------------------------------------------------------
-- Section 8 — Helper: get_or_create_conversation for a couple
------------------------------------------------------------------

create or replace function public.get_or_create_conversation()
returns public.conversations
language plpgsql volatile security definer
set search_path = public
as $$
declare
  v_uid   uuid := auth.uid();
  v_cid   uuid;
  v_conv  public.conversations%rowtype;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  select id into v_cid from public.couples
    where v_uid in (member_a, member_b) and status = 'active' limit 1;
  if v_cid is null then raise exception 'not_paired'; end if;

  select * into v_conv from public.conversations where couple_id = v_cid;
  if not found then
    insert into public.conversations (couple_id) values (v_cid) returning * into v_conv;
  end if;
  return v_conv;
end;
$$;

grant execute on function public.get_or_create_conversation() to authenticated;

------------------------------------------------------------------
-- Section 9 — Realtime publications (Supabase Realtime picks these up)
------------------------------------------------------------------

do $$
declare t text;
begin
  foreach t in array array[
    'messages','feed_items','feed_reactions','feed_comments',
    'presence_taps','watch_together_sessions','mood_checkins',
    'dhikr_contributions','prayer_logs','gratitude_notes',
    'question_answers','conflict_logs'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null; -- publication may not exist yet in migration order
              when others then null;
    end;
  end loop;
end $$;
