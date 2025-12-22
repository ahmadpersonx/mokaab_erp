## Purpose

This file gives concise, repo-specific guidance so AI coding agents can be immediately productive in this Flutter multi-platform ERP project.

## Big Picture
- Flutter app (mobile + web + desktop) organized feature-first under `lib/features/` and shared logic in `lib/core/`.
- App entry and routing: `lib/main.dart` initializes Supabase and registers routes (e.g. `/journal_entries` -> `features/finance/screens/daily_journal_screen.dart`).
- Backend: Supabase is the primary backend integration. Initialization and static keys live in `lib/core/services/supabase_service.dart` (move secrets to env when modifying).
- State & DI: `provider` is used (see `pubspec.yaml`); UI uses Material3 and Arabic RTL defaults (see `lib/main.dart` locale + Directionality).

## Key Files & Patterns (quick reference)
- `lib/main.dart` — app init, Supabase init, theme, locale, top-level routes.
- `lib/core/services/` — platform and backend clients (SupabaseService). Edit here for auth/db clients.
- `lib/core/models/` — data models used across features.
- `lib/features/<feature>/screens/` — screens for a feature (UI entry points). Example: `features/finance/screens/receipt_bonds_screen.dart`.
- `lib/features/<feature>/widgets/` — feature-local reusable widgets.
- `pubspec.yaml` — dependencies (notable: `supabase_flutter`, `provider`, `pdf`, `printing`, `excel`, `file_picker`).
- `assets/` and fonts are declared in `pubspec.yaml` (font family `Cairo`).

## Build / Run / Test (commands)
- Install deps: `flutter pub get`
- Run (default device/emulator): `flutter run`
- Run Windows desktop: `flutter run -d windows`
- Run web (chrome): `flutter run -d chrome`
- Build APK: `flutter build apk`
- Run tests: `flutter test`
- Format: `dart format .` or `flutter format .`

If working with Android Gradle directly: use `android/gradlew.bat assembleDebug` from repo root on Windows.

## Project-specific conventions
- Feature-first layout: add new domain code under `lib/features/<feature>/` with `screens`, `widgets`, and `services` as needed.
- Shared services belong in `lib/core/` (models, services, widgets used across features).
- Routes are centrally registered in `lib/main.dart`. When adding a screen, add its route there.
- Arabic/RTL-first: UI assumes right-to-left; prefer `Directionality(textDirection: TextDirection.rtl)` or use `Directionality` wrapper when creating standalone widgets.
- Fonts/assets: use the `Cairo` font family declared in `pubspec.yaml`.

## Integrations & dependencies to be aware of
- Supabase: `lib/core/services/supabase_service.dart` — client available as `Supabase.instance.client` and session checks like `Supabase.instance.client.auth.currentSession`.
- PDF and printing: `pdf` and `printing` packages used for report exports.
- Excel & file import: `excel`, `file_picker`, `path_provider` for import/export.
- Sharing: `share_plus` used to share generated files.

## Safety and secrets
- The repo currently contains hard-coded Supabase keys in `lib/core/services/supabase_service.dart`. Do not propagate secrets when editing or committing; prefer using secure env vars or CI secrets. If you change this file, update docs and CI accordingly.

## How AI agents should make edits
- Small changes: edit relevant files in place (follow existing folder structure). Example: to add a finance screen, create `lib/features/finance/screens/<name>_screen.dart` and register its route in `lib/main.dart`.
- Large changes: propose a short plan, update TODOs, open a PR with focused commits. Use `flutter test` and `dart format` before committing.
- Avoid changing unrelated platform directories (`android/`, `ios/`, `windows/`) unless explicitly required.

## Where to look for examples
- Routing & session check: [lib/main.dart](lib/main.dart)
- Supabase usage & keys: [lib/core/services/supabase_service.dart](lib/core/services/supabase_service.dart)
- Feature layout examples: `lib/features/finance/screens/` and `lib/features/auth/` directories.

## Quick triage checklist for PRs
- Does `flutter pub get` complete without errors?
- Are new UI changes RTL-friendly?
- Are secrets removed or replaced with placeholders?
- Run `flutter test` and `dart format .` locally.

---
If anything here is unclear or you want more detail (examples for a particular feature, preferred testing commands, or CI notes), tell me which area to expand and I will update this file.
