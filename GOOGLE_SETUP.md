# 🔧 Setup Google Sign-In — Muslim Leveling v6

Wawa udah nulis kodenya. Tinggal setup 3 hal di dashboard Google + Supabase.
Estimasi: **15 menit**.

## 1️⃣ Google Cloud Console
1. Buka https://console.cloud.google.com/
2. Buat project baru (atau pake yang ada)
3. **APIs & Services → OAuth consent screen** → isi nama app, email
4. **Credentials → Create Credentials → OAuth client ID**:
   - **Type: Android**
   - Package name: `id.muslimleveling.muslim_leveling`
   - SHA-1: (lihat cara dapet di bawah)
   - Download → rename jadi `google-services.json`, taruh di `android/app/`
   - **Type: Web application** (WAJIB buat Supabase Auth)
   - Copy **Client ID** (format: `....apps.googleusercontent.com`)

### Cara dapet SHA-1
```bash
cd android
# Debug keystore (udah ada di komputer lo)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Kalau mau release (Play Store), pake keystore lo sendiri
keytool -list -v -keystore ~/path/ke-release.keystore -alias <alias> -storepass <pass> | grep SHA1
```

## 2️⃣ Supabase Dashboard
1. Buka project Supabase lo (URL: `https://hiywlsqaurqvbwwuutbo.supabase.co`)
2. **Authentication → Providers → Google**
3. Enable Google
4. Isi:
   - **Client ID**: dari Web OAuth client di atas
   - **Client Secret**: dari Google Cloud (Web client)
5. **SQL Editor** → paste isi `supabase_rls.sql` → Run

## 3️⃣ Build dengan Web Client ID
Tambahin `--dart-define` pas build biar `google_sign_in` dapet client ID:
```bash
flutter build apk --release \
  --dart-define=GOOGLE_WEB_CLIENT_ID="xxxxx.apps.googleusercontent.com"
```

## ⚠️ Yang BELUM Wawa lakuin (butuh akses punyamu)
- ❌ Bikin `android/app/google-services.json` — butuh SHA-1 dari keystore lo
- ❌ Isi Client Secret di Supabase — butuh credential Google Cloud lo
- ❌ Enable Google provider di Supabase — butuh dashboard access

## ✅ Yang SUDAH Wawa lakuin
- ✅ `pubspec.yaml` — tambah `google_sign_in`
- ✅ `lib/services/auth_service.dart` — full Google login flow
- ✅ `lib/services/supabase_sync.dart` — `initWithUser()` + return bool
- ✅ `lib/main.dart` — restore session + bind uid
- ✅ `lib/screens/profil_tab.dart` — UI "Backup & Akun" (login/logout/status)
- ✅ `lib/services/game_service.dart` — feedback sukses/gagal backup
- ✅ `supabase_rls.sql` — RLS policy (security)

## 🧪 Test lokal
```bash
flutter pub get
flutter analyze   # cek error compile
flutter run        # test di emulator (perlu google-services.json valid)
```

---
**Note:** Tanpa `google-services.json` + Web Client ID, app TETAP JALAN —
cuma tombol "Lanjut dengan Google" yang akan error (gracefully handled,
progress tetap tersimpan lokal). Login cuma unlock fitur cross-device restore.
