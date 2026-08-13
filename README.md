# Fisioterapia Pélvica

🇺🇸 English | [🇧🇷 Português](README.pt-BR.md)

A cross-platform practice management app for pelvic physiotherapy clinics, built with Flutter and Supabase. It runs natively on Android and iOS and is also installable as a Progressive Web App (PWA), sharing a single codebase and backend across all three.

## Overview

The app replaces spreadsheets and paper charts for a solo or small-team physiotherapy practice: patient intake and clinical history, treatment evolution notes, appointment scheduling, and payment tracking, all backed by a Postgres database with row-level security so each therapist only ever sees their own data.

## Features

**Patients**
- Multi-step intake wizard, modeled after a real pelvic physiotherapy clinical assessment form:
  1. Personal data (name, age, phone, profession)
  2. Anamnesis (chief complaint, symptom onset, diagnosis, medical/lifestyle history)
  3. Gynecological history *(female patients only)*
  4. Obstetric history, including a full pregnancy-by-pregnancy record *(female patients only)*
  5. Surgical history
  6. Urinary function
  7. Sexual function
  8. Bowel function
  9. Treatment plan
  10. Physical assessment file upload (photos/PDFs, optional — can also be done later from the patient's Attachments tab)
  11. Consultation fee
- Full read-only clinical record view, organized by section
- Treatment evolution log (dated progress notes) with edit history
- File attachments (photos, PDFs) per patient, categorized automatically, with in-app image preview and secure signed-URL delivery
- Soft delete, and treatment closure with a reason and outcome note (discharged, discontinued, referred, other) — reopenable

**Agenda**
- Rolling 7-day appointment view, grouped by day
- One-tap status changes (scheduled, confirmed, attended, cancelled, no-show, rescheduled)
- Create, edit and delete appointments; link to an existing patient record or type a name freehand
- Past dates are blocked when scheduling
- Monthly report tab with a status breakdown and the full list of appointments in the selected month

**Financial**
- Payment entries linked to a patient (or ad-hoc), with payment method and status
- Monthly report with running total and per-entry breakdown
- Real-time currency input formatting (BRL)
- Delete an entry

**Home dashboard**
- Live-updating "next 7 days" schedule card that recomputes appointment status against the current time, so a past appointment never lingers as "upcoming"
- Clinic overview: active patients, appointments this week, revenue this month

**Account & profile**
- Email/password auth with signup, password reset and email confirmation
- Editable name, profile photo, Crefito (professional license) number
- Language toggle (English/Portuguese), applied across the whole app
- Light/dark theme toggle
- Biometric app lock on mobile (gracefully hidden on web, where the platform doesn't support it)
- Self-service account deletion, cascading to all owned data and storage files

**Installable everywhere**
- Native Android and iOS builds
- Progressive Web App: installable on Android, iOS (Safari "Add to Home Screen") and desktop, opens in standalone mode, works offline for static assets, deep links to password reset/email confirmation adapt automatically between the native URL scheme and the web origin

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Android, iOS, Web) |
| State management | `flutter_bloc` (Cubit) |
| Backend | Supabase (Postgres, Auth, Storage, Row Level Security) |
| Dependency injection | `get_it` |
| Routing | `go_router` |
| Hosting (web) | Cloudflare Workers (static assets) |
| Testing | `flutter_test`, `bloc_test`, `mocktail` |

## Architecture

The codebase follows a pragmatic Clean Architecture, organized by feature rather than by layer at the top level:

```
lib/
├── core/            # Cross-cutting concerns: DI, routing, theming, error handling, env config
├── shared/          # Reusable widgets and utilities with no feature-specific knowledge
└── features/
    ├── auth/
    ├── patients/
    ├── agenda/
    ├── financial/
    ├── profile/
    └── home/
        ├── data/            # Repository implementations (Supabase)
        ├── domain/          # Entities and repository interfaces
        └── presentation/    # Cubits, pages, widgets
```

Each feature only has the layers it actually needs — simple features skip the ceremony a use-case layer would add without real benefit. Errors are modeled explicitly with a `Result<T>` (`Success` / `Error`) type rather than thrown exceptions crossing layer boundaries, so the UI always handles failure states deliberately.

Business logic that doesn't belong in a widget — like grouping appointments by day, or computing whether a slot is "next" vs. "already happened" — lives in small, pure, unit-tested functions instead of inline in `build()` methods.

## Getting started

### Prerequisites
- Flutter SDK (stable channel)
- A Supabase project (see `supabase/migrations` for the schema)

### Setup

```bash
git clone https://github.com/Lucasdiogof/fisioterapia_pelvica.git
cd fisioterapia_pelvica
flutter pub get
cp env.example.json env.json   # then fill in your Supabase URL and publishable key
```

### Run

```bash
# Mobile (device or emulator)
flutter run --dart-define-from-file=env.json

# Web
flutter run -d chrome --dart-define-from-file=env.json
```

### Test

```bash
flutter test
```

## Deployment

- **Android / iOS**: standard `flutter build apk` / `flutter build ios`, not published to the Play Store or App Store — distributed as an installable PWA and direct builds instead.
- **Web**: `flutter build web --release --dart-define-from-file=env.json`, deployed as static assets on Cloudflare Workers (see `wrangler.toml`). Client-side routing falls back to `index.html` via `not_found_handling = "single-page-application"`.
