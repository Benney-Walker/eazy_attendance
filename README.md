# Eazy Attendance

Android app for teachers to mark daily class attendance in **EazyManage**, the school management system by Bynex Labs. It is the native version of the Eazy Attendance web app and talks to the same Spring Boot backend.

Attendance can be marked with or without a connection: every save is written to the phone first and uploaded automatically when the device is online.

## Features

- Staff sign-in with short-lived access tokens, refreshed automatically in the background; the last staff ID is remembered (never the password)
- Pick a class and date, load the roster, mark present/absent (with "All present" / "All absent" and search), save
- Offline-first: classes and rosters are cached in SQLite; saves are queued and synced on reconnect, on app resume, after each save, or from **Settings → Sync now**
- Quiet sync status chip in the app bar, plus a silent notification while syncing

## Tech stack

| Concern | Choice |
|---|---|
| State | [Riverpod](https://riverpod.dev) 2 |
| HTTP | [Dio](https://pub.dev/packages/dio) — one shared `ApiService` with token refresh |
| Local database | [Drift](https://drift.simonbinder.eu) over SQLite |
| Secure storage | `flutter_secure_storage` (Android EncryptedSharedPreferences) |
| Connectivity | `connectivity_plus` plus a reachability check |
| Notifications | `flutter_local_notifications` |
| Fonts | DM Sans / DM Mono, bundled in `assets/fonts/` (no runtime download) |

## Getting started

Requires a Flutter SDK with Dart 3.12 or newer.

```sh
flutter pub get
flutter run
```

The backend URL lives in `lib/core/config/api_config.dart`.

### Regenerating database code

`lib/core/database/app_database.g.dart` is generated and committed. After changing a table in `app_database.dart`, bump `schemaVersion`, add a step to `migration`, then regenerate:

```sh
dart run build_runner build --delete-conflicting-outputs
```

### Tests and analysis

```sh
flutter analyze
flutter test
```

Both run in CI on every push and pull request (`.github/workflows/ci.yml`).

### Release builds

Release builds are signed with the upload key described in `android/key.properties` (git-ignored, never commit it or the `.jks` file). Without that file, release builds fall back to the debug key.

```properties
# android/key.properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=C:/path/to/upload-keystore.jks
```

```sh
flutter build appbundle
# build/app/outputs/bundle/release/app-release.aab
```

Bump `version:` in `pubspec.yaml` for every Play Store upload; the number after `+` must always increase. Update `kAppVersion` in `lib/features/settings/ui/settings_screen.dart` to match.

## Project layout

```
lib/
  main.dart                   App entry: ProviderScope → AuthGate
  core/
    config/                   ApiConfig (base URL, endpoint paths)
    core_providers.dart       Database, secure storage, ApiService, connectivity
    database/                 Drift schema, queries, migrations
    network/                  ApiService (auth headers, refresh-and-retry), ApiException, connectivity
    shell/                    Signed-in shell with bottom navigation
    storage/                  Secure token storage
    sync/                     Offline queue upload, status chip, notifications
    theme/ utils/ widgets/    Design tokens, date helpers, shared widgets
  features/
    auth/                     Sign-in, session restore, sign-out
    home/                     Home overview
    dashboard/                Class + date selection, Load Students
    attendance/               Marking screen, roster and save repositories
    settings/                 Profile, sync, about, sign-out
```

## Backend endpoints

All paths are relative to `/api` on the EazyManage backend.

| Purpose | Request |
|---|---|
| Sign in | `POST /auth/v1/staff-login` with `{ staffId, password }` |
| Refresh access token | `POST /auth/v1/refresh-token` with `{ refreshToken }` |
| Teacher's classes | `GET /staff/v1/load-levels` |
| Class roster for a date | `GET /student/v1/load-students-for-attendance/{levelId}/{yyyy-MM-dd}` |
| Submit attendance | `POST /student/v2/mark-attendance`, headers `selectedDate`, `levelId`, body `[{ studentId, status }]` |

## Privacy

Privacy policy: https://eazyattendanceprivacypolicy.vercel.app
