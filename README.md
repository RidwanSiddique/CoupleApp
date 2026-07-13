# Sakīnah

> وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً — *"And He placed between you affection and mercy"* (Qurʾān 30:21)

A private, two-person Flutter app helping a Muslim husband and wife grow closer to Allah and to each other — daily deen, connection, and long-distance rituals inside an end-to-end encrypted space of two.

**Current status:** Phase 0 (Foundations) — app shell, auth, pairing, prayer-time engine, and design system. Product plan: [`Sakinah_Product_Technical_Plan.docx`](Sakinah_Product_Technical_Plan.docx). Foundation design: [`docs/superpowers/specs/2026-07-12-foundation-design.md`](docs/superpowers/specs/2026-07-12-foundation-design.md).

## Prerequisites

- Flutter 3.44+ (`flutter --version`)
- Xcode 16+ (iOS) / Android SDK 34+ (Android)
- Docker (for local Supabase)
- Supabase CLI: `brew install supabase/tap/supabase`

## First-time setup

```bash
# 1. Install Flutter deps
flutter pub get

# 2. Start local Supabase (Postgres + Auth + Realtime)
supabase start

# 3. Apply migrations
supabase db reset  # runs supabase/migrations/*.sql

# 4. Grab the local anon key that `supabase start` printed
#    (or run `supabase status` to re-print it)
```

## Running the app

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=<the-local-anon-key>
```

For a two-user pairing test, run one instance on the iOS simulator and another on an Android emulator (or two simulator devices).

## Tests

```bash
flutter analyze
flutter test
```

## Project layout

```
lib/
├── core/                    cross-cutting infrastructure
│   ├── config/              env vars, constants
│   ├── crypto/              Signal identity + key vault
│   ├── errors/              AppFailure hierarchy
│   ├── router/              go_router + auth/pairing guards
│   ├── storage/             (Drift DB — Phase 1)
│   ├── theme/               design tokens, ThemeData
│   ├── time/                prayer-time + timezone + Hijri
│   └── widgets/             SakButton, SakCard, SakScaffold, HijriDate
├── features/                one folder per pillar
│   ├── auth/                email-OTP signup
│   ├── home/                Phase-1 placeholder
│   ├── pairing/             invite / accept the "space of two"
│   └── settings/            (Phase 1)
└── shared/
    ├── models/              UserProfile, Couple
    └── providers/           app-scope Riverpod providers

supabase/migrations/         schema + RLS + pairing RPCs
docs/superpowers/specs/      design docs
```

## What's next

Phase 1 — Daily habit + private connection:
Shared prayer log & sync, verse/hadith of day, dua list, question of day, gratitude journal, shared calendar, E2E chat, "Our Wall" feed.
