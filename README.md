# Muslim Leveling V2 — Arena Hikmah

Aplikasi Android yang mengubah ibadah harian menjadi perjalanan leveling ala game
esports. Sholat, zikir, dan modul belajar memberi XP; naik level terbuka tier,
badge, dan border avatar yang semakin loreak seiring progresi.

Dibangun dengan Kotlin + Jetpack Compose + Room. Tema visual "Arena Hikmah":
obsidian/teal/amber/crimson dengan elemen iluminasi Islami (Bintang Seal 8-titik).

## Fitur

- **Sistem leveling sholat** — 5 sholat wajib + 3 sunnah rawatib. Checklist terkunci
  ke jendela waktu masing-masing. Tepat waktu (≤30 menit dari adzan) dapat bonus XP.
- **Tier progresif** — Warrior → Elite → Master → Grandmaster → Epic → Legend →
  Mythic → Mythic Honor → Mythic Glory → Mythic Immortal. Level cap 100.
- **Border avatar tier-progresif** — dari solid 2dp (Warrior) sampai rotating ring +
  particles + crown emblem (Mythic Immortal).
- **Tier-up celebration overlay** — warna & emblem spesifik per tier.
- **Daily Reward Chest** — gacha sistem sudah dihapus, diganti hadiah harian deterministic.
- **Quest harian** — generated berdasarkan intensitas aktivitas.
- **Belajar** — 16 modul, 200 XP per modul.
- **Statistik** — weekly recap, win rate per sholat, longest streak, monthly XP.
- **Profil** — foto profil + border, badge (Subuh Warrior, Mythic Reached, dll).
- **Jadwal sholat** — KEMENAG (`api.myquran.com/v1/sholat`) sebagai sumber utama,
  Aladhan sebagai fallback. 300+ kota Indonesia.
- **Qibla** — kompas berbasis sensor magnetometer + akselerometer.
- **Notifikasi adzan** — `AlarmManager` exact alarm + boot receiver untuk reschedule.

## Stack

- **Kotlin** + **Jetpack Compose** (Material 3)
- **Room** — local persistence (`AppDatabase`)
- **Retrofit** — prayer times API (KEMENAG + Aladhan)
- **AlarmManager** + BroadcastReceiver — jadwal notifikasi adzan
- Min SDK / target SDK — lihat `app/build.gradle.kts`

## Build

```bash
./gradlew assembleDebug        # debug APK
./gradlew assembleRelease      # release APK (perlu signing config)
```

Debug APK butuh `debug.keystore` di root project (CI generate otomatis).

## CI

`.github/workflows/build.yml` — build debug + release APK di push ke `main`.
Release build `continue-on-error` (KSP headless bug di CI headless). Artifact
disimpan 30 hari.

## Struktur

```
app/src/main/java/com/example/
├── MainActivity.kt
├── data/           DataModels, Room (AppDatabase), Retrofit services, city list
├── notifications/  AdhanReminderReceiver, BootReceiver, NotificationScheduler
├── ui/
│   ├── screens/    Home, Quest, Belajar, Profile, Statistik, Onboarding,
│   │               Splash, JadwalSholat, Qibla, Overlays, NotificationHelper
│   ├── components/ CityDropdownPicker, NeonComponents, ProfileAvatar
│   └── theme/      Color, Theme, Type (Arena Hikmah palette)
└── viewmodel/      GameViewModel (logika game: XP, tier, quest, badge)
```

## Konfigurasi

- **`GEMINI_API_KEY`** — required di `.env` untuk build (legacy dari template AI Studio,
  masih di-refer di `build.gradle.kts`). Placeholder cocok untuk build lokal.
- **Prayer times API** — tidak butuh key. KEMENAG public endpoint.
