# Design Spec: Premium Skins & Equipment (v1) — Muslim Leveling v6

**Branch (usulan):** `feat/premium-cosmetics`
**Mode:** design spec (belum implementasi)
**App identity:** Muslim daily practice + gamification (XP, quests, streak, rank tiers).
**Status keputusan:** disetujui user 2026-07-23 (brainstorming). Siap lanjut ke implementation plan.

---

## Goal

Tambahkan sistem **cosmetic skin/equipment premium** yang bisa di-equip di avatar, dimonetisasi lewat **langganan "Pro" bulanan/tahunan**. Fitur ini juga **menghidupkan sistem `GameState.rewards` yang sekarang mati** (10 nama cosmetic dari daily chest yang tidak pernah ditampilkan/di-equip di mana pun).

### Success criteria
1. User bisa **equip / unequip** cosmetic dari tab Profil (Loker) dan langsung terlihat di `TierProfileAvatar`.
2. Cosmetic **free (earned)** bisa dipakai selamanya; cosmetic **Pro** hanya bisa dipakai saat langganan aktif.
3. Saat langganan Pro habis (lapse), item Pro yang ter-equip **otomatis balik ke default free** — tanpa menghapus data, tinggal langganan lagi untuk pakai.
4. **Status Pro** dibaca dari satu abstraksi `EntitlementService`; ganti sumber (dev toggle → billing asli) = **nol perubahan** di UI/game logic.
5. Seluruh fitur bisa dibangun, dites, dan didemokan **tanpa** akun merchant / Play Billing (pakai dev toggle).
6. Diff mengikuti pola repo yang ada (single-file service + static catalog seperti `chestRewardPool`, unit test Dart murni seperti `test/backup_merge_test.dart`).

---

## Prinsip / Guardrails (WAJIB dipegang)

Ini **app ibadah** — monetisasi devosi itu sensitif. Aturan tidak boleh dilanggar:

1. **Cosmetic-only. NO pay-to-win.** Premium TIDAK PERNAH memberi XP, streak freeze tambahan, bonus level, atau keunggulan ibadah apa pun. Hanya mengubah **gaya/bentuk visual**.
2. **Prestige tier tidak bisa dibeli.** Warna & efek tier (Warrior → Immortal) adalah hasil *di-earn* dari naik level. Premium frame hanya mengubah **bentuk/siluet**; warna & efek **tetap mengikuti tier asli** user (lihat "Shield = kanvas" di §Frame).
3. **NO gacha berbayar.** Tidak ada loot box yang dibuka pakai uang (itu judi). Daily chest yang sudah ada tetap gratis (dibuka dengan menyelesaikan ibadah, bukan uang).
4. **Framing jujur.** One-time purchase (fase berikutnya) dijual sebagai pembelian biasa, bukan diberi label "donasi" (kalau user menerima barang digital, Google Play menganggapnya pembelian — bukan donasi).

---

## Scope

### v1 (spec ini)
- Model **2 lapis: Free (earned) + Pro (langganan)**.
- Slot cosmetic: **Frame (B)**, **Aura (C)**, **Title (D)**.
- `EntitlementService` dengan **dev toggle** sebagai sumber status Pro.
- Loker (etalase equip) di tab Profil + halaman Paywall (dummy → dev toggle).
- Target billing = **RevenueCat** (dipasang di fase terpisah, bukan sekarang).

### Ditunda (BUKAN v1)
- **One-time purchase** (miliki 1 skin selamanya) — arsitektur disiapkan, tapi tidak diaktifkan di v1.
- **Slot A (skin karakter/ilustrasi)** & **Slot E (tema warna app)**.
- **Sedekah 100% passthrough** → proyek terpisah (ada kendala Google Play billing untuk donasi amal + butuh partner LAZ resmi + halaman transparansi). Jangan dicampur ke sini.

---

## Strategi pra-rilis (penting)

App **belum rilis** ke Play Store. Justru ini timing terbaik: **pisahkan "apa yang di-unlock" dari "cara bayar".**

- **Sekarang:** `EntitlementService.isPro` dibaca dari **dev toggle / flag lokal**. Seluruh sistem cosmetic + equip + paywall bisa dibangun & dites tanpa uang.
- **Nanti (mau rilis):** ganti implementasi `EntitlementService` ke **RevenueCat** (kelola langganan, validasi receipt server-side, restore purchase, sinkron entitlement). UI & game logic tidak berubah.

**Urutan implementasi yang disarankan:**
1. Bangun `CosmeticCatalog` + data model (owned/equipped) + `TierProfileAvatar` rendering — **tanpa gerbang premium** dulu (semua bisa dicoba).
2. Pasang `EntitlementService` (dev toggle) + gerbang Pro + Loker + Paywall.
3. Colok RevenueCat **paling akhir**, saat benar-benar mau publish.

**Kenapa RevenueCat:** ada langganan bulanan/tahunan; subscription lifecycle (perpanjangan, grace period, lapse, restore) adalah bagian paling rawan bug kalau di-handle manual dengan plugin `in_app_purchase` mentah. RevenueCat punya free tier (sampai ~$2.5k/bln revenue).

---

## Arsitektur / Komponen baru

| Komponen | File (usulan) | Peran |
|---|---|---|
| `EntitlementService` | `lib/services/entitlement_service.dart` | Satu sumber kebenaran status Pro. v1: dev toggle (persisted di SharedPreferences). Nanti: RevenueCat. Expose `bool get isPro`, `ValueNotifier<bool> proStatus`, `Future<void> setProDev(bool)` (dev only), `Future<void> refresh()`. |
| `CosmeticCatalog` | `lib/services/cosmetic_catalog.dart` | Definisi statis semua cosmetic (const list, seperti `chestRewardPool`). Sumber kebenaran metadata cosmetic. |
| `CosmeticService` | perluas `lib/services/game_service.dart` **atau** file baru `lib/services/cosmetic_service.dart` | Kelola `ownedCosmetics` + `equipped`; logika equip/unequip + fallback lapse; migrasi 10 reward lama. |
| `TierProfileAvatar` (perluas) | `lib/widgets/tier_avatar.dart` | Terima `equippedFrameId`, `equippedAuraId`. Render frame (shield clipper + border painter) & aura, **tetap pakai warna/efek tier**. |
| UI Loker | `lib/screens/profil_tab.dart` (+ widget baru mis. `lib/widgets/cosmetic_locker.dart`) | Grid cosmetic per slot: owned → equip, Pro terkunci → gembok → paywall. Tampilkan equipped saat ini. |
| UI Paywall | `lib/screens/pro_paywall_screen.dart` | Halaman langganan Pro. v1: tombol "Aktifkan Pro (dev)" → `EntitlementService.setProDev(true)`. Nanti: tombol beli RevenueCat. |

---

## Data model

### Perubahan `GameState` (`lib/services/game_service.dart`)

Tambah dua field (ikuti pola `fromMap`/`toMap`/`copyWith` yang sudah ada):

```dart
final List<String> ownedCosmetics;   // id cosmetic yang dimiliki (earned/free). Pro items TIDAK disimpan di sini.
final Map<String,String> equipped;    // slot -> cosmeticId, mis. {'frame':'shield_crest','aura':'nur_emas','title':'tahajjud_slayer'}
```

- Default: `ownedCosmetics = const []`, `equipped = const {}`.
- Serialisasi ke JSON di `toMap()` + parse aman di `fromMap()` (backward-compatible: field lama tetap terbaca; app versi lama abaikan field baru).

### Status Pro TIDAK disimpan di `GameState`
Status Pro hidup di `EntitlementService` (disinkron via billing / dev toggle), **bukan** di `GameState`. Alasan: kalau disimpan di game state yang di-backup ke Supabase, user bisa memalsukan status Pro dengan mengedit/restore backup. Entitlement harus divalidasi dari sumber billing.

### Migrasi 10 reward lama (`GameState.rewards`)
`rewards` sekarang berisi **nama tampilan** (mis. `"Gelar Pembasmi Sunyi Tahajjud"`, `"Efek Aura Sultan"`), bukan id. Buat peta `legacyRewardName -> cosmeticId` di `CosmeticCatalog`. Saat load, untuk tiap nama di `rewards` yang cocok → tambahkan id-nya ke `ownedCosmetics` (idempoten). `rewards` **tetap dipertahankan** untuk backward-compat; `ownedCosmetics` jadi sumber kebenaran baru.

---

## CosmeticCatalog — struktur

```dart
enum CosmeticSlot { frame, aura, title }
enum CosmeticAccess { free, pro }   // one-time menyusul → tambah `oneTime` nanti

class Cosmetic {
  final String id;                 // stabil, dipakai di equipped/owned. mis. 'shield_crest'
  final CosmeticSlot slot;
  final String name;               // label tampilan
  final String emoji;              // ikon ringkas untuk grid (reuse gaya chest)
  final CosmeticAccess access;     // free | pro
  final String? legacyRewardName;  // nama di `rewards` lama, untuk migrasi (nullable)
  // Parameter visual (dibaca renderer). Isi sesuai slot:
  final FrameShape? frameShape;    // untuk slot frame: squareRounded | shieldClassic | shieldCrest | shieldGeometric
  final AuraSpec?   auraSpec;      // untuk slot aura: warna/pola partikel
  final String?     titleText;     // untuk slot title
}
```

- Katalog = `static const List<Cosmetic> all = [...]` (satu tempat, mudah ditambah).
- Renderer avatar **hanya** membaca `frameShape` / `auraSpec` — tidak ada logika bisnis di widget.

### Katalog awal (starter — bisa ditambah nanti)

**Frame (B)**
| id | nama | akses | shape |
|---|---|---|---|
| `frame_default` | Kotak Klasik | free | squareRounded (bentuk existing) |
| `frame_earned_01` | (frame earned dari chest) | free | squareRounded varian |
| `shield_classic` | Perisai Klasik | pro | shieldClassic |
| `shield_crest` | Perisai Bersayap | pro | shieldCrest |
| `shield_geometric` | Perisai Geometris | pro | shieldGeometric |

**Aura (C)**
| id | nama | akses |
|---|---|---|
| `aura_none` | Tanpa Aura (default) | free |
| `aura_sultan` | Aura Sultan | free (migrasi dari `"Efek Aura Sultan"`) |
| `aura_tahajjud` | Cahaya Tahajjud | pro |
| `aura_nur_emas` | Nur Emas | pro |

**Title (D)**
| id | nama | akses |
|---|---|---|
| `title_none` | (tanpa gelar) | free |
| `title_tahajjud_slayer` | Pembasmi Sunyi Tahajjud | free (migrasi dari reward lama) |
| `title_maghrib_guard` | Penjaga Maghrib | free (migrasi) |
| `title_pro_exclusive_01` | (gelar eksklusif Pro) | pro |

> Angka pasti (berapa banyak per slot) final-kan saat implementasi. Ini kerangka minimal yang sudah nyambung ke reward chest lama.

---

## Frame = "kanvas", tier tetap tembus (keputusan A)

Avatar sekarang: **kotak-rounded 16dp**, border digambar `_GradientBorderPainter` (rounded-rect) di `tier_avatar.dart`.

Premium frame (shield) mengubah **bentuk/siluet** saja:
- Ganti clip rounded-rect → **custom `Path` shield/crest** (sudut atas membulat, bawah meruncing).
- Border painter mengikuti bentuk shield.
- **Warna & efek TETAP dari `TierVisualConfig`** (opsi A): Grandmaster → shield emas; Mythic → shield berpartikel; Immortal → shield + mahkota. Prestige tidak dibeli, cuma bentuknya beda.
- Layer efek existing (glow, rotating ring, particles, sparkles) menyesuaikan siluet shield atau duduk di belakangnya.

**Implikasi teknis:** `TierProfileAvatar._buildMainAvatar` dan painter perlu abstraksi bentuk (mis. `ShapeBuilder` yang menghasilkan `Path` dari `frameShape`), supaya rounded-rect & shield berbagi jalur render.

---

## Alur

### Equip
1. User tap cosmetic di Loker.
2. Kalau `access == free` **dan** ada di `ownedCosmetics` → set `equipped[slot] = id`, save.
3. Kalau `access == pro`:
   - `EntitlementService.isPro == true` → equip.
   - else → buka **Paywall**.

### Render (`TierProfileAvatar`)
1. Baca `equipped['frame']` / `equipped['aura']`.
2. Untuk tiap item, **verifikasi masih boleh dipakai**:
   - free → cukup ada di `ownedCosmetics`.
   - pro → `EntitlementService.isPro == true`.
3. Kalau tidak boleh → **fallback** ke default free (`frame_default` / `aura_none`).

### Lapse (langganan Pro habis)
- Saat app load / `EntitlementService.refresh()` mengubah status ke non-Pro:
  - Scan `equipped`; slot mana pun yang berisi cosmetic `access == pro` → **kosongkan / set ke default free**, save.
  - **Jangan hapus** apa pun dari `ownedCosmetics` (Pro items memang tidak disimpan di situ; free items tetap utuh).
  - Efek: avatar mulus balik ke tampilan free. User langganan lagi → item Pro bisa di-equip lagi.

---

## Billing (fase terpisah, catatan)

- Target: **RevenueCat**. Produk: 1 langganan Pro (bulanan + tahunan sebagai 2 harga).
- `EntitlementService` di-refactor jadi baca `CustomerInfo.entitlements['pro'].isActive`.
- Butuh: Google Play Developer account + merchant, konfigurasi produk di Play Console, app minimal di testing track untuk tes purchase asli.
- **Google Play policy:** langganan/skin digital → **wajib** Play Billing. (Donasi amal TIDAK boleh lewat Play Billing kecuali nonprofit terverifikasi → itu urusan proyek Sedekah terpisah.)

---

## Testing

Unit test Dart murni (pola `test/backup_merge_test.dart`):
- Migrasi: `rewards` lama → `ownedCosmetics` terisi id yang benar (idempoten, tidak dobel).
- Equip free owned → tersimpan; equip pro saat non-Pro → ditolak (tidak tersimpan).
- Render fallback: equipped pro + non-Pro → resolve ke default free.
- Lapse: status Pro true→false → `equipped` slot pro dikosongkan; free slot tidak terganggu.
- Serialisasi: `toMap`/`fromMap` round-trip untuk `ownedCosmetics` & `equipped`; backward-compat (map lama tanpa field baru tetap load).

---

## Keputusan yang sudah dikunci (brainstorming 2026-07-23)

1. Model bisnis: **Hybrid** (langganan + one-time), tapi **v1 = Free + Pro saja**; one-time menyusul.
2. One-time = pembelian biasa (tanpa framing "donasi").
3. Slot v1: **B (frame/shield), C (aura), D (title)**.
4. Premium frame = **shield ala Strava** (ganti bentuk), **tier tetap tembus (opsi A)**.
5. Lapse → **auto-unequip ke default free, data tidak dihapus**.
6. Pendekatan: **bangun cosmetic dulu, billing (RevenueCat) paling akhir**, lewat `EntitlementService`.
7. Sedekah 100% = **proyek terpisah**, tidak di sini.

## Open items (untuk implementation plan)
- Jumlah pasti cosmetic per slot & aset visual final (shield shapes).
- Naming id final + daftar peta migrasi `legacyRewardName -> id` lengkap (10 item chest).
- `CosmeticService` digabung ke `GameService` atau file sendiri (lean ke file sendiri kalau `game_service.dart` sudah besar).
- Harga langganan (bulanan/tahunan) — keputusan bisnis, tidak blokir implementasi.

---

## File yang akan disentuh (perkiraan)
- `lib/services/entitlement_service.dart` (baru)
- `lib/services/cosmetic_catalog.dart` (baru)
- `lib/services/cosmetic_service.dart` (baru, atau perluas `game_service.dart`)
- `lib/services/game_service.dart` (tambah field `ownedCosmetics`, `equipped` + migrasi)
- `lib/widgets/tier_avatar.dart` (render frame shield + aura; abstraksi bentuk)
- `lib/widgets/cosmetic_locker.dart` (baru)
- `lib/screens/profil_tab.dart` (pasang Loker)
- `lib/screens/pro_paywall_screen.dart` (baru)
- `test/cosmetic_service_test.dart` (baru)
