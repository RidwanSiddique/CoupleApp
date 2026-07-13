# Sakīnah — Foundation (Phase 0 + Pairing) Design

Date: 2026-07-12
Status: Approved to implement
Source plan: `Sakinah_Product_Technical_Plan.docx` §4 (Phase 0), §5 (Architecture), §5.3 (Data model), §5.4 (E2E)

## Goal

Ship the skeleton the rest of Sakīnah is built on: a Flutter app that a couple can install, sign into, and securely pair into a private "space of two". Everything downstream (prayer log, chat, feed) plugs into the primitives established here.

**Scope inclusions** (locked with user 2026-07-12):
- Flutter 3.44 app, package `com.sakinah.app`, project name `sakinah`
- Feature-first architecture, Riverpod 3 with code-gen
- Local Supabase (docker) with migrations checked into repo
- Auth (email + OTP via Supabase)
- Pairing flow (invite code + QR, atomic RPC accept)
- Signal identity key bundle generation at signup (private in secure storage, public uploaded) — chat itself is deferred to Phase 1
- Prayer-time + timezone + Hijri engine (pure Dart, tested)
- Design system tokens + a minimal set of primitives (SakButton, SakCard, SakScaffold, HijriDate)
- Drift local DB + thin write-queue sync layer
- Unit tests for time engine and pairing helpers

**Scope exclusions** (deferred):
- Chat UI + libsignal ratchet
- Our Wall feed, verses/duas seed, Ramadan mode, calls, notifications (FCM), i18n/RTL beyond scaffolding

## Architecture

Feature-first module layout. Each feature owns its `data/`, `domain/`, `presentation/` layers. `core/` holds cross-cutting infra.

```
sakinah/
├── android/, ios/, ...              (flutter platforms)
├── lib/
│   ├── main.dart
│   ├── app.dart                     MaterialApp.router + theme
│   ├── core/
│   │   ├── config/                  env, SupabaseClient bootstrap, constants
│   │   ├── theme/                   design tokens, ThemeData
│   │   ├── router/                  go_router config, guards
│   │   ├── errors/                  AppFailure + mappers
│   │   ├── time/                    timezone, hijri, prayer-time engine (pure)
│   │   ├── storage/                 secure_storage wrapper, Drift DB
│   │   ├── crypto/                  Signal key bundle gen (libsignal_protocol_dart)
│   │   └── widgets/                 SakButton, SakCard, SakScaffold, HijriDate
│   ├── features/
│   │   ├── auth/                    signup / signin / OTP
│   │   ├── pairing/                 invite gen, QR, code entry, couple watcher
│   │   ├── home/                    placeholder Phase-1 shell
│   │   └── settings/                madhhab, calc method, timezone override
│   └── shared/
│       ├── models/                  freezed data classes
│       └── providers/               app-scope Riverpod providers
├── supabase/
│   ├── config.toml
│   └── migrations/
│       └── 20260712_0001_foundation.sql
├── test/                            unit + widget tests
└── docs/superpowers/specs/          (this file)
```

Cross-cutting choices:
- **State**: Riverpod 3, code-gen via `@riverpod`
- **Nav**: `go_router` with typed routes and an `AsyncNotifier`-backed auth+pairing guard
- **Models**: `freezed` + `json_serializable`
- **Local DB**: `drift` with a `pending_writes` queue for offline mutations
- **Remote**: `supabase_flutter`, providers wrap channels/streams
- **Keystore**: `flutter_secure_storage` for Signal privates + Supabase refresh tokens

## Data model (Phase 0)

Tables created now — some prepped for Phase 1 so RLS is consistent from day one.

```
users
  id            uuid pk = auth.users.id
  display_name  text
  timezone      text                       IANA tz
  madhhab       text  default 'shafi'      shafi | hanafi
  calc_method   text  default 'MWL'        adhan CalculationMethod enum
  push_token    text nullable
  created_at    timestamptz default now()

signal_key_bundles
  user_id       uuid fk users.id
  device_id     text
  registration_id integer
  identity_pub  bytea
  signed_prekey_id integer
  signed_prekey_pub bytea
  signed_prekey_sig bytea
  one_time_prekeys jsonb                   [{id, pub_key}]
  updated_at    timestamptz default now()
  primary key (user_id, device_id)

couples
  id            uuid pk default gen_random_uuid()
  member_a      uuid fk users.id
  member_b      uuid fk users.id
  status        text default 'active'      active | archived
  anniversary_greg date nullable
  anniversary_hijri text nullable          "YYYY-MM-DD" Hijri string
  long_distance boolean default false
  created_at    timestamptz default now()
  check (member_a <> member_b)
  check (member_a < member_b)              normalized order
  unique (member_a, member_b)

pairing_invites
  code          text pk                    6-char base32, uppercase, no ambiguous chars
  inviter_id    uuid fk users.id
  created_at    timestamptz default now()
  expires_at    timestamptz                +10 minutes
  consumed_at   timestamptz nullable
  consumed_by   uuid fk users.id nullable

prayer_logs                                  (created now, used in Phase 1)
  id            uuid pk default gen_random_uuid()
  couple_id     uuid fk couples.id
  user_id       uuid fk users.id
  date          date
  prayer        text  check in ('fajr','dhuhr','asr','maghrib','isha')
  status        text  check in ('prayed','missed','skipped')
  time_logged   timestamptz default now()
  unique (couple_id, user_id, date, prayer)
```

## RLS policies

Every couple-scoped table gets the same predicate:

```sql
using (
  exists (
    select 1 from couples c
    where c.id = row.couple_id
      and auth.uid() in (c.member_a, c.member_b)
  )
)
with check (same predicate)
```

`users`: read = self OR spouse-of-couple. Update = self.

`signal_key_bundles`: read = self OR spouse (needed for X3DH later). Insert/update = self.

`pairing_invites`: read = inviter OR anyone presenting exact `code` (enforced via SECURITY DEFINER RPC — no direct row read).

`couples`: read/write via RPC only for creation; direct read allowed to members.

## Pairing flow (atomic)

Two Postgres RPCs (SECURITY DEFINER, run as service role):

```sql
create_pairing_invite() returns table(code text, expires_at timestamptz)
  -- Preconditions: caller has no active couple; caller has no unexpired invite.
  -- Generates a 6-char base32 code (Crockford, ambiguity-stripped), inserts row.

accept_pairing_invite(p_code text) returns couples
  -- Preconditions: code exists, not expired, not consumed, inviter <> caller,
  --                caller has no active couple, inviter has no active couple.
  -- In a single transaction:
  --   1. mark invite consumed
  --   2. insert couples row with (member_a, member_b) sorted by uuid
  -- Returns the couples row.
```

Client flow:
1. **Signup** → user row + Signal identity generated locally (private → secure storage, public bundle → `signal_key_bundles`).
2. **First-run**: if not in a couple, show pairing screen with two tabs — *Invite* and *Join*.
3. **Invite tab**: call `create_pairing_invite()`, show the code + QR (deep link `sakinah://pair?code=...`) with a countdown.
4. **Join tab**: scan QR or type code → `accept_pairing_invite()` → router pushes to home.
5. **Realtime**: inviter subscribes to `couples` filtered on `member_a=me OR member_b=me`; the moment a row appears, inviter's screen auto-transitions.

## Prayer-time & timezone engine

Pure functions in `core/time/`:

```dart
sealed class Prayer { fajr, dhuhr, asr, maghrib, isha }

class PrayerLocation { double lat; double lon; String tz; }

class PrayerConfig { CalculationMethod method; Madhhab madhhab; }

DateTime prayerTime(Prayer p, DateTime date, PrayerLocation loc, PrayerConfig cfg);
Iterable<(Prayer, DateTime)> prayerTimesForDay(DateTime date, PrayerLocation loc, PrayerConfig cfg);
(Prayer, DateTime) nextPrayer(DateTime now, PrayerLocation loc, PrayerConfig cfg);

// Hijri helpers
HijriDate toHijri(DateTime greg);
DateTime toGregorian(HijriDate hijri);
```

Backed by the `adhan` package for calculation and `hijri` for calendar conversion. All functions are deterministic — timezone comes from `loc.tz` rather than device time — so tests are reproducible.

**Tests** (`test/core/time/`):
- Asr differs between Shafi and Hanafi at a known lat/lon
- DST spring-forward and fall-back in America/New_York
- High latitude fallback (e.g. Reykjavík summer) doesn't crash and picks the expected fallback method
- Hijri conversion round-trips for known ceremonial dates (Ramadan 1 1446, Eid al-Fitr 1446)

## Signal identity generation

`core/crypto/signal_keys.dart` produces, at first signup:

```dart
class GeneratedKeyBundle {
  int registrationId;
  Uint8List identityPub;
  Uint8List identityPriv;         // stored in secure_storage only
  int signedPrekeyId;
  Uint8List signedPrekeyPub;
  Uint8List signedPrekeyPriv;     // secure_storage
  Uint8List signedPrekeySig;
  List<PreKeyRecord> oneTimePrekeys; // 20 initially
}
```

Public halves + signatures uploaded to `signal_key_bundles`. Privates keyed in secure storage under `signal.identity.priv`, `signal.spk.<id>.priv`, `signal.otpk.<id>.priv`. A `keyExists()` check runs at every startup to detect device-migration cases — Phase 1 chat will add the recovery-passphrase backup.

## Design system

`core/theme/tokens.dart` exports:
- Colors: `SakColors.background`, `SakColors.surface`, `SakColors.accent`, `SakColors.mutedText`, plus semantic `success/warning/error`. Palette leans warm neutrals with a single Sakīnah green accent (`#2F6B5C` placeholder — designer-swappable).
- Typography: `Instrument Serif` (display), `Inter` (body), `Amiri` (Arabic). Loaded via `google_fonts`.
- Spacing scale: `SakSpace.xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48`.
- Radii: `SakRadius.sm=8, md=12, lg=24`.
- Elevation: soft, single-shadow tokens; no Material heavy shadows.

`core/widgets/`:
- `SakButton` — filled / outlined / text variants, loading state
- `SakCard` — rounded, subtle shadow, tap ripple
- `SakScaffold` — safe-area + optional Hijri/Gregorian dual-date header
- `HijriDate` — renders "12 Muḥarram 1448 · 12 Jul 2026"

Both light and dark ThemeData built from tokens; system-follows by default.

## Router + guards

```dart
GoRouter routes:
  /splash                         boot / hydrate session
  /auth/sign-in
  /auth/sign-up
  /auth/otp
  /pair                           invite + accept tabs
  /home                           placeholder for Phase 1

Redirect logic:
  no session          → /auth/sign-in
  session, no couple  → /pair
  session + couple    → /home
```

## Offline persistence

`core/storage/db.dart` — Drift database with:
- `local_users` (self + spouse cache)
- `local_couples` (single-row cache)
- `local_prayer_logs` (populated in Phase 1)
- `pending_writes` (id, table, op, payload_json, created_at) — mutations queued when offline, drained by a `SyncNotifier` on connectivity.

Foundation ships the schema and the write-queue drainer harness. Real usage begins in Phase 1.

## Testing strategy

- **Unit** (`test/`): time engine, invite-code generator (uniqueness, no ambiguous chars, checksum optional), payload serialisers.
- **Widget** (`test/features/pairing/`): invite tab renders code + countdown; join tab validates input; expired code path.
- **Integration** (`test/integration/pairing_test.dart`): script that boots local Supabase and runs `create_pairing_invite → accept_pairing_invite` against real RLS. Skipped when `SUPABASE_LOCAL=0` env is set.

CI target (post-foundation, not this phase): `flutter analyze` clean, `flutter test` green.

## Dependencies (all pulled latest at install time)

Runtime:
- `flutter_riverpod`, `riverpod_annotation`
- `go_router`
- `freezed_annotation`, `json_annotation`
- `supabase_flutter`
- `drift`, `drift_flutter`, `sqlite3_flutter_libs`
- `adhan`, `hijri`, `timezone`
- `flutter_secure_storage`
- `google_fonts`
- `qr_flutter`, `mobile_scanner`
- `libsignal_protocol_dart`
- `uuid`, `intl`

Dev:
- `build_runner`, `riverpod_generator`, `freezed`, `json_serializable`, `drift_dev`
- `flutter_lints`
- `mocktail`

## Success criteria

- `flutter analyze` reports zero issues
- `flutter test` passes, including time-engine + pairing-helper unit tests
- App launches on iOS simulator and Android emulator; sign-up creates a user in local Supabase; two accounts can pair via QR/code and both land on `/home`
- Signal key bundle rows exist for both users after signup
- RLS blocks a third account from reading either couple's rows (verified via integration script)

## Risks

- **libsignal Dart binding maturity** — mitigation: keep the key-gen path behind a `CryptoService` interface so we can swap implementations without touching call sites.
- **Drift + supabase_flutter version conflicts** — mitigation: use `flutter pub add` (gets latest), lock only if a real conflict surfaces.
- **Local Supabase requires Docker** — mitigation: `README.md` documents `supabase start` prerequisite; integration tests skip cleanly when unavailable.
