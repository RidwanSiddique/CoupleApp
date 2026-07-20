# Sakīnah

> وَجَعَلَ بَيْنَكُم مَّوَدَّةً وَرَحْمَةً — *"And He placed between you affection and mercy"* (Qurʾān 30:21)

A private, two-person Flutter app helping a Muslim husband and wife grow closer to Allah and to each other — daily deen, connection, and long-distance rituals inside an end-to-end encrypted space of two.

**Built so far:** app shell + design system, email OTP **and** email/password auth (with password reset), role-based onboarding (gender → husband/wife), pairing (the "space of two"), prayer-time engine, shared prayer log, daily verse/hadith/question, duas, gratitude, menstrual cycle tracker, cycle-aware prayer scoring, role-specific care dashboards, settings, and **end-to-end encrypted chat** (Signal session layer + text messages, replies, encrypted reactions, delivered/read receipts, typing).

Design docs live in [`docs/superpowers/specs/`](docs/superpowers/specs/).

---

## Prerequisites

- **Flutter 3.44+** — `flutter --version`
- **Xcode 16+** (iOS/macOS) and/or **Android SDK 34+**
- **Supabase CLI** — `brew install supabase/tap/supabase`
- **Docker Desktop** — only for the local-Supabase path below (path A)

```bash
flutter pub get
cp config/supabase.cloud.example.json config/supabase.cloud.json   # then edit it (path B)
```

The app reads its backend URL + key from **`--dart-define`** (compile-time), so you pass a small JSON config on every run. Both config files are gitignored.

> **Platforms:** iOS, Android, and macOS. **Web is not supported** — the local database (Drift/`sqlite3`) uses `dart:ffi`, which the web compiler forbids.

---

## Run path A — with Docker (local Supabase)

Everything runs on your machine: Postgres, Auth, Realtime, and **Mailpit** (a local inbox that catches all auth emails). Best for development.

```bash
# 1. Start the local stack (needs Docker running)
supabase start

# 2. Apply all migrations from scratch (+ seed data)
supabase db reset

# 3. Print the local URL + anon key
supabase status
```

Put those values in **`config/supabase.local.json`**:

```json
{
  "SUPABASE_URL": "http://127.0.0.1:54321",
  "SUPABASE_ANON_KEY": "<anon key from `supabase status`>",
  "OTP_LENGTH": 6
}
```

Run the app:

```bash
flutter run --dart-define-from-file=config/supabase.local.json
```

- **Auth emails (OTP / signup confirm / password reset):** open **Mailpit** at <http://127.0.0.1:54324> and copy the 6-digit code from there.
- To reset the database at any time: `supabase db reset`. To stop the stack: `supabase stop`.

---

## Run path B — without Docker (Supabase Cloud)

No Docker; the app talks to a hosted Supabase project. Production-style. Migrations are pushed over the network (`db push` does **not** need Docker).

```bash
# 1. Link this repo to your cloud project (one-time)
supabase login
supabase link --project-ref <your-project-ref>     # ref = the subdomain of your project URL

# 2. Push all local migrations to the cloud database
supabase db push
```

Fill in **`config/supabase.cloud.json`** from **Supabase dashboard → Project Settings → API** (use the *anon / publishable* key, never `service_role`):

```json
{
  "SUPABASE_URL": "https://<your-project-ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon / publishable key>",
  "OTP_LENGTH": 6
}
```

Run the app:

```bash
flutter run --dart-define-from-file=config/supabase.cloud.json
```

**One-time dashboard setup for auth:**

1. **Authentication → Providers → Email:** set **Email OTP Length** to **6** (or set `"OTP_LENGTH"` in the config to whatever your project issues).
2. **Authentication → Email Templates:** the *Confirm signup*, *Magic Link*, and *Reset Password* templates must each include the code token `{{ .Token }}` (the defaults only contain a link).
3. **Auth email delivery:** either use Supabase's built-in email (rate-limited, fine for a couple of tests) or, for repeated testing, set a **custom SMTP** under *Project Settings → Auth → SMTP* pointing at a sandbox inbox like **[Mailtrap](https://mailtrap.io)** (`sandbox.smtp.mailtrap.io`) — the cloud equivalent of Mailpit.

---

## Choosing a target device

```bash
flutter devices                                   # list connected devices/simulators
flutter run -d <device-id> --dart-define-from-file=config/supabase.local.json
```

- **iOS Simulator:** its "location" is a hardcoded default (San Francisco). To get correct prayer times, set **Features → Location → Custom Location** to your real coordinates.
- **Physical iPhone:** open `ios/Runner.xcworkspace` in Xcode and set a Signing Team once, then `flutter run -d <device>`.

**Testing chat / pairing** needs **two** signed-in, paired accounts on **two** devices at once (e.g. two simulators, or an iOS simulator + the macOS app), both pointed at the same backend. Pair them with the invite code from the pairing screen.

---

## Tests

```bash
flutter analyze
flutter test
```

> Some tests are **integration tests** that talk to a real local Supabase (repository, RPC, and end-to-end chat tests hit `127.0.0.1:54321`). They require **path A's `supabase start`** to be running; with the stack down, only the pure unit/widget tests pass.

---

## Project layout

```
lib/
├── core/
│   ├── config/          compile-time env (Env.supabaseUrl / OTP_LENGTH)
│   ├── crypto/          Signal session layer: key gen, KeyVault, SecureStore,
│   │   └── stores/      Drift-backed identity/session/prekey stores
│   ├── errors/          AppFailure hierarchy
│   ├── router/          go_router + auth / onboarding / pairing guards
│   ├── storage/         Drift database (Signal state + local chat history)
│   ├── theme/ time/ motion/ widgets/   design system + prayer/Hijri engine
├── features/            one folder per pillar (data / domain / presentation)
│   ├── auth/ onboarding/ pairing/      identity, gender/role, space-of-two
│   ├── prayer_log/ scoring/ cycle/     prayer tracking + cycle-aware scoring
│   ├── daily/ duas/ gratitude/ care/   deen content + wellbeing
│   ├── chat/            E2E messaging (payload, service, store, screen)
│   ├── settings/ home/ location/
└── shared/              models + app-scope providers

supabase/migrations/     schema, RLS, RPCs (source of truth for both paths)
docs/superpowers/        design specs + implementation plans
config/                  dart-define configs (gitignored; *.example.json tracked)
```

---

## Troubleshooting

- **`refresh_token_not_found` on launch** — a stale session in the Keychain (common after `supabase db reset` wipes local auth). Uninstall the app from the device/simulator, or Simulator → *Erase All Content and Settings*, then re-run.
- **OTP code doesn't match** — the app's slot count (`OTP_LENGTH`) must equal the project's Email OTP Length. Request a fresh code after changing either.
- **`Could not choose the best candidate function` (PGRST203)** — a migration left two overloads of an RPC; re-run `supabase db reset` (path A) after pulling the latest migrations.
- **dart-define changes not taking effect** — dart-defines are compile-time; stop and re-run (a hot restart won't pick them up).
