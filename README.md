# Muslim Leveling

Flutter Android app: prayer quests, XP, streaks, adzan reminders. Local-first; Google login = optional cloud backup.

**Version:** `1.9.1+21` · **Package:** `id.muslimleveling.muslim_leveling` · **Branch:** `main`

## Stack

- Flutter (Dart 3.12+)
- SharedPreferences (source of truth)
- Supabase Auth + row sync (signed-in only)
- Google Sign-In → Supabase
- `flutter_local_notifications` + timezone (Asia/Jakarta)
- Sentry (client DSN)

## Features

- 5 daily prayers + rawatib / tilawah / sedekah quests
- XP, level, hero streak, achievements
- Jadwal Kemenag (`api.myquran.com`) + Aladhan fallback
- City picker (onboarding, Jadwal, Profil)
- Adzan notif: fokus / seimbang / intensif · senyap / suara / adzan
- Qibla compass
- Light (Strava neutrals) + dark (#000) · Electric Jade brand
- Haid mode freezes streaks

## Setup

```bash
flutter pub get
flutter run
```

Release APK (needs local keystore):

```bash
# repo root key.properties (gitignored)
# storeFile=/absolute/path/to/muslim-leveling-release.jks
# storePassword=…
# keyAlias=muslim-leveling
# keyPassword=…

flutter build apk --release --target-platform android-arm64
```

Google login release: register SHA-1 of the release keystore in Google Cloud + Supabase OAuth redirect  
`id.muslimleveling.muslim_leveling://login-callback`.

## Architecture (short)

| Layer | Role |
|---|---|
| `GameService` | Local game state; fire-and-forget `SupabaseSync.saveGame` |
| `PrayerService` | City + jadwal cache; `locationVersion` notifies tabs |
| `NotificationService` | Exact/inexact schedule; 3 Android channels |
| `AuthService` | Google → Supabase session |
| `SupabaseSync` | No network until signed in |

Tabs live in `IndexedStack` (`DashboardShell`). Location change bumps `locationVersion` → Home reschedules adzan, Jadwal refetches.

## Git / release

- Trunk-based on `main`; CI: analyze + arm64 release APK artifact
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- Tags: `v1.9.1` (current)
- Never commit: `key.properties`, `*.jks`, `.env*`, secret screenshots

## Notes

- Notif timezone pinned WIB (`Asia/Jakarta`). WITA/WIT needs city→TZ map later.
- Hardcoded Supabase anon key / Sentry DSN / OAuth client ID are public client credentials; RLS owns data isolation.
