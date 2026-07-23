# Ship checklist — Muslim Leveling 1.9.1

Single-user Android sideload. No Play staged rollout.

## Pre-launch

| Gate | Result |
|---|---|
| `flutter analyze` | clean |
| `flutter test` | 15/15 after golden refresh |
| Secrets in git | none (`key.properties` / jks ignored) |
| CI main | green (analyze + arm64 APK artifact) |
| Version | `1.9.1+21` · tag `v1.9.1` |
| Changelog | `CHANGELOG.md` |
| Sentry | client DSN in app |
| Signed release keystore | local `~/muslim-leveling-release.jks` SHA-1 `DF:2C:7E:…` |

## Smoke on device (first hour)

1. Install APK over previous build.
2. Open → splash → Home loads quests.
3. Profil → Notifikasi ON → izin notif + alarm + battery → Tes Notifikasi + Tes Adzan.
4. Pending count > 0 after enable.
5. Ganti kota → jadwal berubah.
6. (Opsional) Google backup: sign-in → reinstall → progress restored.

## Success = ship

- Notif fires at prayer wall-clock WIB (not +7h).
- No crash on cold start / tab switch.
- Sentry quiet (no new issue flood).

## Rollback

| Trigger | Action |
|---|---|
| Crash / data loss | reinstall previous APK from GitHub Actions artifact / prior sideload |
| Bad notif schedule | Profil → matikan pengingat; or reinstall prior APK |
| Bad cloud merge | local SharedPreferences is source of truth; sign out to stop cloud writes |

Git rollback (next build only):

```bash
git revert <bad-sha> && git push origin main
# or sideload APK from previous successful CI run
```

No DB migration. Local prefs survive reinstall only if backup/Google path used.

## Out of scope this ship

- Play Store listing / staged % rollout / feature flags
- WITA/WIT timezone map
- R8 minify re-enable
