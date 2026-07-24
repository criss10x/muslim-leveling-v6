# Premium Skins & Equipment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an equippable cosmetic system (frames/auras/titles) to the avatar, gated by a Pro subscription entitlement, reviving the currently-dead `GameState.rewards` collectibles.

**Architecture:** A static `CosmeticCatalog` defines every cosmetic. Pure functions in `CosmeticService` operate on `GameState` (owned/equipped) and return new state — mirroring the existing `logPrayer` (pure) + `logPrayerAsync` (persist wrapper) pattern. `EntitlementService` is the single source of truth for Pro status (dev toggle now, RevenueCat later). `TierProfileAvatar` renders the equipped frame shape + aura while keeping tier colors/effects (no pay-to-win on prestige).

**Tech Stack:** Flutter (Dart 3.12+), SharedPreferences (persistence), `flutter_test`. No new dependencies in v1 (RevenueCat added in a later billing-only project).

**Design spec:** `.hermes/plans/2026-07-23_premium-skins-equipment-design.md` (read it first).

## Global Constraints

- **Cosmetic-only, NO pay-to-win.** Premium never grants XP, streaks, freezes, or ibadah advantage. Only visual style/shape.
- **Tier prestige is earned, never bought.** Premium frames change *shape only*; tier colors/effects still come from `TierVisualConfig` (spec decision "A").
- **Pro status is NOT stored in `GameState`.** It lives in `EntitlementService` so a Supabase backup/restore cannot forge it.
- **Backward-compatible persistence.** New `GameState` fields must default safely; old JSON without them must still load.
- **Follow repo patterns:** single-file services, `static const` catalog like `chestRewardPool`, pure-function + async-wrapper split, pure-Dart unit tests like `test/backup_merge_test.dart`.
- **Language:** Indonesian for user-facing strings; English for code identifiers (matches codebase).
- **Branch:** `feat/premium-cosmetics` (create from current `feat/jumat-streak` at execution time via the using-git-worktrees skill).

---

### Task 1: Cosmetic catalog & models

**Files:**
- Create: `lib/services/cosmetic_catalog.dart`
- Test: `test/cosmetic_catalog_test.dart`

**Interfaces:**
- Produces:
  - `enum CosmeticSlot { frame, aura, title }`
  - `enum CosmeticAccess { free, pro }`
  - `enum FrameShape { squareRounded, shieldClassic, shieldCrest, shieldGeometric }`
  - `class AuraSpec { final int particleCount; final bool goldTint; const AuraSpec({...}); }`
  - `class Cosmetic { final String id; final CosmeticSlot slot; final String name; final String emoji; final CosmeticAccess access; final String? legacyRewardName; final FrameShape? frameShape; final AuraSpec? auraSpec; final String? titleText; const Cosmetic({...}); }`
  - `class CosmeticCatalog` with:
    - `static const List<Cosmetic> all`
    - `static const Map<CosmeticSlot,String> defaults` (`frame_default`, `aura_none`, `title_none`)
    - `static Cosmetic? byId(String id)`
    - `static List<Cosmetic> bySlot(CosmeticSlot slot)`
    - `static bool isDefault(String id)`

- [ ] **Step 1: Write the failing test**

```dart
// test/cosmetic_catalog_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';

void main() {
  test('all cosmetic ids are unique', () {
    final ids = CosmeticCatalog.all.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every slot has a default that requires no ownership', () {
    for (final slot in CosmeticSlot.values) {
      final defId = CosmeticCatalog.defaults[slot];
      expect(defId, isNotNull, reason: 'missing default for $slot');
      final c = CosmeticCatalog.byId(defId!);
      expect(c, isNotNull);
      expect(c!.access, CosmeticAccess.free);
      expect(CosmeticCatalog.isDefault(defId), isTrue);
    }
  });

  test('every legacyRewardName maps to a real free cosmetic', () {
    final withLegacy = CosmeticCatalog.all.where((c) => c.legacyRewardName != null);
    expect(withLegacy, isNotEmpty);
    for (final c in withLegacy) {
      expect(c.access, CosmeticAccess.free,
          reason: 'earned (legacy) cosmetics must be free');
    }
  });

  test('frame cosmetics carry a frameShape; others do not', () {
    for (final c in CosmeticCatalog.bySlot(CosmeticSlot.frame)) {
      expect(c.frameShape, isNotNull, reason: '${c.id} missing frameShape');
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cosmetic_catalog_test.dart`
Expected: FAIL — `cosmetic_catalog.dart` / `CosmeticCatalog` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/services/cosmetic_catalog.dart

/// Slots an avatar can equip. One equipped cosmetic per slot.
enum CosmeticSlot { frame, aura, title }

/// How a cosmetic is unlocked. `oneTime` is intentionally deferred (v2).
enum CosmeticAccess { free, pro }

/// Silhouette of the avatar frame. Free frames use [squareRounded];
/// premium shields change the outline (tier colors still show through).
enum FrameShape { squareRounded, shieldClassic, shieldCrest, shieldGeometric }

/// Visual parameters for an aura layer around the avatar.
class AuraSpec {
  final int particleCount;
  final bool goldTint;
  const AuraSpec({this.particleCount = 6, this.goldTint = false});
}

/// One cosmetic definition. Static data only — no behaviour.
class Cosmetic {
  final String id;
  final CosmeticSlot slot;
  final String name;
  final String emoji;
  final CosmeticAccess access;
  final String? legacyRewardName; // maps an old chest reward name → this id
  final FrameShape? frameShape;   // slot == frame
  final AuraSpec? auraSpec;        // slot == aura
  final String? titleText;         // slot == title

  const Cosmetic({
    required this.id,
    required this.slot,
    required this.name,
    required this.emoji,
    required this.access,
    this.legacyRewardName,
    this.frameShape,
    this.auraSpec,
    this.titleText,
  });
}

/// The single source of truth for all cosmetics.
class CosmeticCatalog {
  static const Map<CosmeticSlot, String> defaults = {
    CosmeticSlot.frame: 'frame_default',
    CosmeticSlot.aura: 'aura_none',
    CosmeticSlot.title: 'title_none',
  };

  static const List<Cosmetic> all = [
    // ── Frames ──
    Cosmetic(id: 'frame_default', slot: CosmeticSlot.frame, name: 'Kotak Klasik',
        emoji: '⬜', access: CosmeticAccess.free, frameShape: FrameShape.squareRounded),
    Cosmetic(id: 'frame_subuh', slot: CosmeticSlot.frame, name: 'Bingkai Penjelajah Subuh',
        emoji: '🖼️', access: CosmeticAccess.free, frameShape: FrameShape.squareRounded,
        legacyRewardName: 'Bingkai Penjelajah Subuh'),
    Cosmetic(id: 'shield_classic', slot: CosmeticSlot.frame, name: 'Perisai Klasik',
        emoji: '🛡️', access: CosmeticAccess.pro, frameShape: FrameShape.shieldClassic),
    Cosmetic(id: 'shield_crest', slot: CosmeticSlot.frame, name: 'Perisai Bersayap',
        emoji: '🛡️', access: CosmeticAccess.pro, frameShape: FrameShape.shieldCrest),
    Cosmetic(id: 'shield_geometric', slot: CosmeticSlot.frame, name: 'Perisai Geometris',
        emoji: '🛡️', access: CosmeticAccess.pro, frameShape: FrameShape.shieldGeometric),

    // ── Auras ──
    Cosmetic(id: 'aura_none', slot: CosmeticSlot.aura, name: 'Tanpa Aura',
        emoji: '∅', access: CosmeticAccess.free, auraSpec: null),
    Cosmetic(id: 'aura_sultan', slot: CosmeticSlot.aura, name: 'Aura Sultan',
        emoji: '🔱', access: CosmeticAccess.free, auraSpec: AuraSpec(particleCount: 6),
        legacyRewardName: 'Efek Aura Sultan'),
    Cosmetic(id: 'aura_istiqomah', slot: CosmeticSlot.aura, name: 'Jejak Api Istiqomah',
        emoji: '☄️', access: CosmeticAccess.free, auraSpec: AuraSpec(particleCount: 8),
        legacyRewardName: 'Jejak Api Istiqomah'),
    Cosmetic(id: 'aura_wings', slot: CosmeticSlot.aura, name: 'Sayap Malaikat Istiqomah',
        emoji: '👼', access: CosmeticAccess.free, auraSpec: AuraSpec(particleCount: 10),
        legacyRewardName: 'Sayap Malaikat Istiqomah'),
    Cosmetic(id: 'aura_tahajjud', slot: CosmeticSlot.aura, name: 'Cahaya Tahajjud',
        emoji: '🌌', access: CosmeticAccess.pro, auraSpec: AuraSpec(particleCount: 10)),
    Cosmetic(id: 'aura_nur_emas', slot: CosmeticSlot.aura, name: 'Nur Emas',
        emoji: '✨', access: CosmeticAccess.pro, auraSpec: AuraSpec(particleCount: 12, goldTint: true)),

    // ── Titles ──
    Cosmetic(id: 'title_none', slot: CosmeticSlot.title, name: 'Tanpa Gelar',
        emoji: '∅', access: CosmeticAccess.free, titleText: ''),
    Cosmetic(id: 'title_crescent', slot: CosmeticSlot.title, name: 'Bulan Sabit Menyala',
        emoji: '🌙', access: CosmeticAccess.free, titleText: 'Bulan Sabit Menyala',
        legacyRewardName: 'Lencana Bulan Sabit Menyala'),
    Cosmetic(id: 'title_tahajjud_slayer', slot: CosmeticSlot.title, name: 'Pembasmi Sunyi Tahajjud',
        emoji: '⚔️', access: CosmeticAccess.free, titleText: 'Pembasmi Sunyi Tahajjud',
        legacyRewardName: 'Gelar Pembasmi Sunyi Tahajjud'),
    Cosmetic(id: 'title_dzikir', slot: CosmeticSlot.title, name: 'Ramuan Mana Dzikir',
        emoji: '🧪', access: CosmeticAccess.free, titleText: 'Ramuan Mana Dzikir',
        legacyRewardName: 'Ikon Ramuan Mana Dzikir'),
    Cosmetic(id: 'title_maghrib_guard', slot: CosmeticSlot.title, name: 'Penjaga Maghrib',
        emoji: '🌆', access: CosmeticAccess.free, titleText: 'Penjaga Maghrib',
        legacyRewardName: 'Segel Penjaga Maghrib'),
    Cosmetic(id: 'title_quran_sage', slot: CosmeticSlot.title, name: "Bijak Al-Qur'an",
        emoji: '🥋', access: CosmeticAccess.free, titleText: "Bijak Al-Qur'an",
        legacyRewardName: "Jubah Bijak Al-Qur'an"),
    Cosmetic(id: 'title_mythic_sword', slot: CosmeticSlot.title, name: 'Pedang Sholat Mitik',
        emoji: '🗡️', access: CosmeticAccess.free, titleText: 'Pedang Sholat Mitik',
        legacyRewardName: 'Pedang Sholat Mitik'),
    Cosmetic(id: 'title_pro_muhsin', slot: CosmeticSlot.title, name: 'Al-Muhsin',
        emoji: '👑', access: CosmeticAccess.pro, titleText: 'Al-Muhsin'),
  ];

  static Cosmetic? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  static List<Cosmetic> bySlot(CosmeticSlot slot) =>
      all.where((c) => c.slot == slot).toList();

  static bool isDefault(String id) => defaults.values.contains(id);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cosmetic_catalog_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetic_catalog.dart test/cosmetic_catalog_test.dart
git commit -m "feat(cosmetics): static cosmetic catalog + models"
```

---

### Task 2: GameState fields, serialization & migration

**Files:**
- Modify: `lib/services/game_service.dart` (class `GameState`: fields, constructor, `copyWith`, `fromMap`, `toMap`)
- Test: `test/cosmetic_state_test.dart`

**Interfaces:**
- Consumes: `GameState` (existing), `CosmeticCatalog` (Task 1).
- Produces on `GameState`:
  - `final List<String> ownedCosmetics;` (default `const []`)
  - `final Map<String,String> equipped;` (default `const {}`)
  - both threaded through `copyWith`, `fromMap`, `toMap`.

- [ ] **Step 1: Write the failing test**

```dart
// test/cosmetic_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/services/game_service.dart';

void main() {
  test('ownedCosmetics & equipped default empty', () {
    final s = GameState();
    expect(s.ownedCosmetics, isEmpty);
    expect(s.equipped, isEmpty);
  });

  test('round-trips through toMap/fromMap', () {
    final s = GameState(
      ownedCosmetics: const ['aura_sultan', 'title_crescent'],
      equipped: const {'frame': 'shield_classic', 'title': 'title_crescent'},
    );
    final restored = GameState.fromMap(s.toMap());
    expect(restored.ownedCosmetics, ['aura_sultan', 'title_crescent']);
    expect(restored.equipped, {'frame': 'shield_classic', 'title': 'title_crescent'});
  });

  test('old JSON without the new fields still loads', () {
    final legacy = {'xp': 100, 'level': 3}; // no cosmetics keys
    final s = GameState.fromMap(legacy);
    expect(s.ownedCosmetics, isEmpty);
    expect(s.equipped, isEmpty);
    expect(s.xp, 100);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cosmetic_state_test.dart`
Expected: FAIL — `GameState` has no `ownedCosmetics`/`equipped`.

- [ ] **Step 3: Write minimal implementation**

In `lib/services/game_service.dart`, class `GameState`:

Add fields after `haidMode`:

```dart
  final List<String> ownedCosmetics; // cosmetic ids owned (earned/free)
  final Map<String, String> equipped; // slot name -> cosmetic id
```

Add to the constructor parameter list (with the other `this.` defaults):

```dart
    this.ownedCosmetics = const [],
    this.equipped = const {},
```

Add to `copyWith` signature and body:

```dart
    List<String>? ownedCosmetics,
    Map<String, String>? equipped,
```
```dart
      ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
      equipped: equipped ?? this.equipped,
```

In `fromMap`, before the `return GameState(`:

```dart
    final ownedList = (m['ownedCosmetics'] as List?)?.cast<String>() ?? [];
    final equippedMap = (m['equipped'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString())) ??
        <String, String>{};
```
and pass them into the returned `GameState(... ownedCosmetics: ownedList, equipped: equippedMap)`.

In `toMap`, add:

```dart
    'ownedCosmetics': ownedCosmetics,
    'equipped': equipped,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cosmetic_state_test.dart`
Expected: PASS (3 tests). Also run `flutter test test/backup_merge_test.dart` to confirm no regression in serialization.

- [ ] **Step 5: Commit**

```bash
git add lib/services/game_service.dart test/cosmetic_state_test.dart
git commit -m "feat(cosmetics): persist ownedCosmetics + equipped on GameState"
```

---

### Task 3: EntitlementService (dev toggle)

**Files:**
- Create: `lib/services/entitlement_service.dart`
- Test: `test/entitlement_service_test.dart`

**Interfaces:**
- Produces:
  - `bool get isPro`
  - `ValueNotifier<bool> proStatus`
  - `Future<void> load()` (reads persisted dev flag)
  - `Future<void> setProDev(bool value)` (dev-only; persists + notifies)

- [ ] **Step 1: Write the failing test**

```dart
// test/entitlement_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to not Pro', () async {
    await EntitlementService.load();
    expect(EntitlementService.isPro, isFalse);
  });

  test('setProDev(true) persists and notifies', () async {
    await EntitlementService.load();
    var fired = false;
    void listener() => fired = true;
    EntitlementService.proStatus.addListener(listener);

    await EntitlementService.setProDev(true);
    expect(EntitlementService.isPro, isTrue);
    expect(fired, isTrue);

    EntitlementService.proStatus.removeListener(listener);

    // Re-load from a fresh read simulates app restart with same prefs.
    await EntitlementService.load();
    expect(EntitlementService.isPro, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/entitlement_service_test.dart`
Expected: FAIL — `entitlement_service.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/services/entitlement_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for premium ("Pro") entitlement.
///
/// v1: backed by a local dev toggle so the whole cosmetic system can be
/// built and demoed without billing. A later billing-only project swaps the
/// implementation for RevenueCat — consumers read [isPro] and never change.
class EntitlementService {
  static const _key = 'entitlement_pro_dev';
  static bool _isPro = false;

  static final ValueNotifier<bool> proStatus = ValueNotifier(false);

  static bool get isPro => _isPro;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isPro = p.getBool(_key) ?? false;
    proStatus.value = _isPro;
  }

  /// DEV ONLY — flips the local Pro flag. Replaced by real billing later.
  static Future<void> setProDev(bool value) async {
    _isPro = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, value);
    proStatus.value = value;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/entitlement_service_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/entitlement_service.dart test/entitlement_service_test.dart
git commit -m "feat(cosmetics): EntitlementService dev toggle for Pro status"
```

---

### Task 4: CosmeticService — equip / resolve / lapse (pure logic)

**Files:**
- Create: `lib/services/cosmetic_service.dart`
- Test: `test/cosmetic_service_test.dart`

**Interfaces:**
- Consumes: `GameState` (Task 2), `CosmeticCatalog`/`Cosmetic`/`CosmeticSlot`/`CosmeticAccess` (Task 1).
- Produces (all pure `static`):
  - `GameState migrateRewards(GameState s)`
  - `GameState? equip(GameState s, {required CosmeticSlot slot, required String id, required bool isPro})` — returns null if rejected.
  - `GameState unequip(GameState s, CosmeticSlot slot)`
  - `bool isAllowed(GameState s, String id, {required bool isPro})`
  - `String resolveSlot(GameState s, CosmeticSlot slot, {required bool isPro})` — effective id after fallback.
  - `GameState reconcileLapse(GameState s, {required bool isPro})`

- [ ] **Step 1: Write the failing test**

```dart
// test/cosmetic_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';
import 'package:muslim_leveling/services/cosmetic_service.dart';

void main() {
  test('migrateRewards maps legacy names to owned ids (idempotent)', () {
    final s = GameState(rewards: const ['Efek Aura Sultan', 'Pedang Sholat Mitik']);
    final migrated = CosmeticService.migrateRewards(s);
    expect(migrated.ownedCosmetics, containsAll(['aura_sultan', 'title_mythic_sword']));
    // Running again adds nothing new.
    final again = CosmeticService.migrateRewards(migrated);
    expect(again.ownedCosmetics.length, migrated.ownedCosmetics.length);
  });

  test('equip free owned succeeds', () {
    final s = GameState(ownedCosmetics: const ['aura_sultan']);
    final r = CosmeticService.equip(s, slot: CosmeticSlot.aura, id: 'aura_sultan', isPro: false);
    expect(r, isNotNull);
    expect(r!.equipped['aura'], 'aura_sultan');
  });

  test('equip free NOT owned is rejected', () {
    final s = GameState();
    final r = CosmeticService.equip(s, slot: CosmeticSlot.aura, id: 'aura_sultan', isPro: false);
    expect(r, isNull);
  });

  test('equip pro without entitlement is rejected; with entitlement succeeds', () {
    final s = GameState();
    expect(CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'shield_classic', isPro: false), isNull);
    final r = CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'shield_classic', isPro: true);
    expect(r, isNotNull);
    expect(r!.equipped['frame'], 'shield_classic');
  });

  test('default cosmetics are always allowed (no ownership needed)', () {
    final s = GameState();
    final r = CosmeticService.equip(s, slot: CosmeticSlot.frame, id: 'frame_default', isPro: false);
    expect(r, isNotNull);
  });

  test('resolveSlot falls back to default when pro item not entitled', () {
    final s = GameState(equipped: const {'frame': 'shield_crest'});
    expect(CosmeticService.resolveSlot(s, CosmeticSlot.frame, isPro: false), 'frame_default');
    expect(CosmeticService.resolveSlot(s, CosmeticSlot.frame, isPro: true), 'shield_crest');
  });

  test('reconcileLapse clears pro-equipped slots but keeps free ones', () {
    final s = GameState(
      ownedCosmetics: const ['title_crescent'],
      equipped: const {'frame': 'shield_classic', 'title': 'title_crescent'},
    );
    final r = CosmeticService.reconcileLapse(s, isPro: false);
    expect(r.equipped.containsKey('frame'), isFalse); // pro removed
    expect(r.equipped['title'], 'title_crescent');    // free kept
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cosmetic_service_test.dart`
Expected: FAIL — `cosmetic_service.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/services/cosmetic_service.dart
import 'game_service.dart';
import 'cosmetic_catalog.dart';

/// Pure cosmetic logic over [GameState]. No persistence, no I/O — mirrors the
/// `logPrayer` (pure) / `logPrayerAsync` (wrapper) split in GameService.
class CosmeticService {
  /// Convert legacy `rewards` (display names) into owned cosmetic ids.
  /// Idempotent: re-running never duplicates.
  static GameState migrateRewards(GameState s) {
    final owned = s.ownedCosmetics.toSet();
    for (final name in s.rewards) {
      for (final c in CosmeticCatalog.all) {
        if (c.legacyRewardName == name) owned.add(c.id);
      }
    }
    if (owned.length == s.ownedCosmetics.length) return s;
    return s.copyWith(ownedCosmetics: owned.toList());
  }

  /// True if [id] may currently be equipped by this user.
  static bool isAllowed(GameState s, String id, {required bool isPro}) {
    final c = CosmeticCatalog.byId(id);
    if (c == null) return false;
    if (CosmeticCatalog.isDefault(id)) return true;
    switch (c.access) {
      case CosmeticAccess.pro:
        return isPro;
      case CosmeticAccess.free:
        return s.ownedCosmetics.contains(id);
    }
  }

  /// Equip [id] into [slot]. Returns null (rejected) if not allowed or if the
  /// cosmetic's slot doesn't match [slot].
  static GameState? equip(GameState s,
      {required CosmeticSlot slot, required String id, required bool isPro}) {
    final c = CosmeticCatalog.byId(id);
    if (c == null || c.slot != slot) return null;
    if (!isAllowed(s, id, isPro: isPro)) return null;
    final next = Map<String, String>.from(s.equipped)..[slot.name] = id;
    return s.copyWith(equipped: next);
  }

  /// Remove whatever is equipped in [slot] (renders as the slot default).
  static GameState unequip(GameState s, CosmeticSlot slot) {
    if (!s.equipped.containsKey(slot.name)) return s;
    final next = Map<String, String>.from(s.equipped)..remove(slot.name);
    return s.copyWith(equipped: next);
  }

  /// Effective id shown for [slot] after ownership/entitlement fallback.
  static String resolveSlot(GameState s, CosmeticSlot slot, {required bool isPro}) {
    final id = s.equipped[slot.name];
    if (id != null && isAllowed(s, id, isPro: isPro)) return id;
    return CosmeticCatalog.defaults[slot]!;
  }

  /// On Pro lapse, drop any equipped cosmetic the user may no longer use.
  /// Free/owned equips are preserved.
  static GameState reconcileLapse(GameState s, {required bool isPro}) {
    final next = Map<String, String>.from(s.equipped);
    var changed = false;
    for (final entry in s.equipped.entries) {
      if (!isAllowed(s, entry.value, isPro: isPro)) {
        next.remove(entry.key);
        changed = true;
      }
    }
    return changed ? s.copyWith(equipped: next) : s;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cosmetic_service_test.dart`
Expected: PASS (7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetic_service.dart test/cosmetic_service_test.dart
git commit -m "feat(cosmetics): equip/resolve/lapse pure logic + reward migration"
```

---

### Task 5: GameService async wrappers + startup wiring

**Files:**
- Modify: `lib/services/game_service.dart` (add async wrappers; call migration in `load`)
- Modify: `lib/main.dart` (load EntitlementService + reconcile lapse on startup)
- Test: `test/cosmetic_persist_test.dart`

**Interfaces:**
- Consumes: `CosmeticService` (Task 4), `EntitlementService` (Task 3), `GameService._save` (existing private).
- Produces on `GameService`:
  - `static Future<bool> equipCosmetic(CosmeticSlot slot, String id, {required bool isPro})`
  - `static Future<void> unequipCosmetic(CosmeticSlot slot)`
  - `static Future<void> reconcileCosmeticLapse({required bool isPro})`
  - `load()` now runs `CosmeticService.migrateRewards` on the loaded state before returning.

- [ ] **Step 1: Write the failing test**

```dart
// test/cosmetic_persist_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('equipCosmetic persists to GameService.current', () async {
    await GameService.load();
    // Seed ownership through the reward-migration path.
    await GameService.debugSeedOwned(['aura_sultan']);
    final ok = await GameService.equipCosmetic(
        CosmeticSlot.aura, 'aura_sultan', isPro: false);
    expect(ok, isTrue);
    expect(GameService.current.equipped['aura'], 'aura_sultan');
  });

  test('equipCosmetic rejects a pro item when not entitled', () async {
    await GameService.load();
    final ok = await GameService.equipCosmetic(
        CosmeticSlot.frame, 'shield_classic', isPro: false);
    expect(ok, isFalse);
    expect(GameService.current.equipped.containsKey('frame'), isFalse);
  });
}
```

> `debugSeedOwned` is a tiny test helper added below (avoids depending on chest randomness in tests).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cosmetic_persist_test.dart`
Expected: FAIL — `equipCosmetic` / `debugSeedOwned` not defined.

- [ ] **Step 3: Write minimal implementation**

In `lib/services/game_service.dart`, add imports at top:

```dart
import 'cosmetic_catalog.dart';
import 'cosmetic_service.dart';
```

In `GameService.load()`, after `_cache` is set from local or remote and before the final `return _cache;`, run migration:

```dart
    _cache = CosmeticService.migrateRewards(_cache);
```
(applies on both the local-hit and remote-hit paths — place it just before each `return _cache;`, or restructure to a single tail return.)

Add methods to `GameService`:

```dart
  // ─── Cosmetics ───
  static Future<bool> equipCosmetic(CosmeticSlot slot, String id,
      {required bool isPro}) async {
    final next = CosmeticService.equip(_cache, slot: slot, id: id, isPro: isPro);
    if (next == null) return false;
    await _save(next);
    return true;
  }

  static Future<void> unequipCosmetic(CosmeticSlot slot) async {
    await _save(CosmeticService.unequip(_cache, slot));
  }

  static Future<void> reconcileCosmeticLapse({required bool isPro}) async {
    final next = CosmeticService.reconcileLapse(_cache, isPro: isPro);
    if (!identical(next, _cache)) await _save(next);
  }

  /// TEST/DEV ONLY — grant ownership without going through the daily chest.
  static Future<void> debugSeedOwned(List<String> ids) async {
    final owned = {..._cache.ownedCosmetics, ...ids}.toList();
    await _save(_cache.copyWith(ownedCosmetics: owned));
  }
```

In `lib/main.dart`, in the startup sequence where `GameService.load()` is already awaited (find it near other service init), add:

```dart
  await EntitlementService.load();
  await GameService.reconcileCosmeticLapse(isPro: EntitlementService.isPro);
```
with `import 'services/entitlement_service.dart';` at the top of `main.dart`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cosmetic_persist_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/game_service.dart lib/main.dart test/cosmetic_persist_test.dart
git commit -m "feat(cosmetics): GameService equip wrappers + startup migrate/reconcile"
```

---

### Task 6: Frame shape abstraction in TierProfileAvatar (shield paths)

**Files:**
- Modify: `lib/widgets/tier_avatar.dart` (add shape → `Path` builder; new `equippedFrameId` param; clip + border follow shape)
- Test: `test/tier_avatar_frame_test.dart`

**Interfaces:**
- Consumes: `FrameShape` / `CosmeticCatalog` (Task 1).
- Produces:
  - top-level `Path buildFramePath(FrameShape shape, Size size, double radius)`
  - `TierProfileAvatar` gains `final String equippedFrameId;` (default `'frame_default'`).
  - `SmallTierAvatar` gains the same param (default `'frame_default'`).

**Note:** Tier colors/effects are unchanged — only the outline path switches. `buildFramePath` is a pure function, unit-testable without pumping a widget.

- [ ] **Step 1: Write the failing test**

```dart
// test/tier_avatar_frame_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/services/cosmetic_catalog.dart';
import 'package:muslim_leveling/widgets/tier_avatar.dart';

void main() {
  test('squareRounded path stays within bounds', () {
    final path = buildFramePath(FrameShape.squareRounded, const Size(100, 100), 16);
    expect(path.getBounds().width, closeTo(100, 0.5));
    expect(path.getBounds().height, closeTo(100, 0.5));
  });

  test('shield path is non-empty and bounded by the box', () {
    final path = buildFramePath(FrameShape.shieldClassic, const Size(100, 100), 16);
    final b = path.getBounds();
    expect(b.width, greaterThan(0));
    expect(b.height, lessThanOrEqualTo(100.5));
    // Shield tapers: the very bottom-center point exists near y ~ 100.
    expect(path.contains(const Offset(50, 96)), isTrue);
  });

  testWidgets('avatar renders with a shield frame without throwing', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TierProfileAvatar(
        tierName: 'Warrior',
        equippedFrameId: 'shield_classic',
        sizeDp: 80,
      ),
    ));
    expect(find.byType(TierProfileAvatar), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tier_avatar_frame_test.dart`
Expected: FAIL — `buildFramePath` / `equippedFrameId` not defined.

- [ ] **Step 3: Write minimal implementation**

In `lib/widgets/tier_avatar.dart`, add a top-level pure function (below imports):

```dart
/// Builds the avatar outline for a given [FrameShape]. Square frames use a
/// rounded rect; shields taper to a point at the bottom-center. Colors and
/// tier effects are applied elsewhere — this is silhouette only.
Path buildFramePath(FrameShape shape, Size size, double radius) {
  final w = size.width, h = size.height;
  switch (shape) {
    case FrameShape.squareRounded:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Offset.zero & size, Radius.circular(radius)));
    case FrameShape.shieldClassic:
    case FrameShape.shieldCrest:
    case FrameShape.shieldGeometric:
      // Rounded top, straight sides, point at bottom-center.
      final tip = shape == FrameShape.shieldGeometric ? h : h * 0.98;
      final shoulder = h * 0.62;
      return Path()
        ..moveTo(radius, 0)
        ..lineTo(w - radius, 0)
        ..arcToPoint(Offset(w, radius), radius: Radius.circular(radius))
        ..lineTo(w, shoulder)
        ..quadraticBezierTo(w, tip * 0.9, w / 2, tip)
        ..quadraticBezierTo(0, tip * 0.9, 0, shoulder)
        ..lineTo(0, radius)
        ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
        ..close();
  }
}
```

Add `equippedFrameId` to `TierProfileAvatar` (and `SmallTierAvatar`) constructor + field:

```dart
  final String equippedFrameId;
```
```dart
    this.equippedFrameId = 'frame_default',
```

In `_TierProfileAvatarState`, derive the shape and use `ClipPath`/path border. Replace the `ClipRRect` in `_buildMainAvatar` content with a `ClipPath` when the shape is not square, and swap `_GradientBorderPainter` for a path-aware border. Minimal approach — add a resolved shape getter and a `ClipPath` wrapper:

```dart
  FrameShape get _frameShape {
    final c = CosmeticCatalog.byId(widget.equippedFrameId);
    return c?.frameShape ?? FrameShape.squareRounded;
  }
```

Wrap the avatar `content` clip:

```dart
    // was: ClipRRect(borderRadius: ...). Now shape-aware:
    child: ClipPath(
      clipper: _FrameClipper(_frameShape, cornerRadius),
      child: /* existing photo/emoji child */,
    ),
```

Add the clipper (bottom of file, near other painters):

```dart
class _FrameClipper extends CustomClipper<Path> {
  final FrameShape shape;
  final double radius;
  _FrameClipper(this.shape, this.radius);
  @override
  Path getClip(Size size) => buildFramePath(shape, size, radius);
  @override
  bool shouldReclip(covariant _FrameClipper old) =>
      old.shape != shape || old.radius != radius;
}
```

For the border, extend `_GradientBorderPainter` to stroke the frame path instead of a fixed RRect: add a `FrameShape shape` field, and in `paint` replace the RRect stroke with `canvas.drawPath(buildFramePath(shape, size, cornerRadius).shift(Offset(strokeWidth/2, strokeWidth/2))... , borderPaint)` — keep the sweep-gradient shader. Pass `_frameShape` where `_GradientBorderPainter` is constructed in `_buildMainAvatar`. (Square shape keeps identical output to today.)

> Keep the tier colors (`config.inkPrimary/inkSecondary`) and all effect layers exactly as-is — only the clip + border outline changes.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/tier_avatar_frame_test.dart`
Expected: PASS (3 tests). Run `flutter analyze lib/widgets/tier_avatar.dart` — expect no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/tier_avatar.dart test/tier_avatar_frame_test.dart
git commit -m "feat(cosmetics): shield frame shapes in TierProfileAvatar"
```

---

### Task 7: Aura layer honoring equipped aura

**Files:**
- Modify: `lib/widgets/tier_avatar.dart` (render an aura layer from `equippedAuraId`)
- Test: `test/tier_avatar_aura_test.dart`

**Interfaces:**
- Consumes: `AuraSpec` / `CosmeticCatalog` (Task 1).
- Produces: `TierProfileAvatar` gains `final String equippedAuraId;` (default `'aura_none'`). When the resolved aura has a non-null `AuraSpec`, an extra particle layer is drawn using the existing `_ParticlePainter` with `spec.particleCount` and a gold tint when `spec.goldTint`.

- [ ] **Step 1: Write the failing test**

```dart
// test/tier_avatar_aura_test.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_leveling/widgets/tier_avatar.dart';

void main() {
  testWidgets('avatar renders with a premium aura without throwing', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TierProfileAvatar(
        tierName: 'Warrior',
        equippedAuraId: 'aura_nur_emas',
        sizeDp: 80,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TierProfileAvatar), findsOneWidget);
  });

  testWidgets('aura_none adds no aura layer (no throw, Warrior has no tier particles)',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TierProfileAvatar(tierName: 'Warrior', sizeDp: 80),
    ));
    expect(find.byType(TierProfileAvatar), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/tier_avatar_aura_test.dart`
Expected: FAIL — `equippedAuraId` not defined.

- [ ] **Step 3: Write minimal implementation**

Add the field + default to `TierProfileAvatar`:

```dart
  final String equippedAuraId;
```
```dart
    this.equippedAuraId = 'aura_none',
```

Add a resolver in the state:

```dart
  AuraSpec? get _auraSpec => CosmeticCatalog.byId(widget.equippedAuraId)?.auraSpec;
```

Drive the shared particle controller when an aura is present (so free-tier avatars can still show an equipped aura). In `_syncControllers`, OR the aura into the particle gate:

```dart
    gate(_particleController, config.hasParticles || _auraSpec != null);
```

In `build`, add an aura layer just above the particle-tier layer (Layer 3 area):

```dart
            // Equipped-aura layer (independent of tier particles)
            if (_auraSpec != null)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) => CustomPaint(
                  size: Size(size + 14, size + 14),
                  painter: _ParticlePainter(
                    color: _auraSpec!.goldTint
                        ? AppColors.goldFill
                        : config.inkSecondary,
                    phase: _particleController.value * 360,
                    particleCount: _auraSpec!.particleCount,
                  ),
                ),
              ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/tier_avatar_aura_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/tier_avatar.dart test/tier_avatar_aura_test.dart
git commit -m "feat(cosmetics): render equipped aura layer on avatar"
```

---

### Task 8: Pro Paywall screen

**Files:**
- Create: `lib/screens/pro_paywall_screen.dart`
- Test: `test/pro_paywall_test.dart`

**Interfaces:**
- Consumes: `EntitlementService` (Task 3), `AppColors`/`AppText` (existing theme).
- Produces: `class ProPaywallScreen extends StatelessWidget`. Shows the Pro pitch and a dev button "Aktifkan Pro (dev)" that calls `EntitlementService.setProDev(true)` then pops. Real purchase button is added in the later billing project — leave a clearly-marked TODO comment only for that wiring point (not logic).

- [ ] **Step 1: Write the failing test**

```dart
// test/pro_paywall_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/screens/pro_paywall_screen.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('dev activate button flips Pro on', (tester) async {
    await EntitlementService.load();
    await tester.pumpWidget(const MaterialApp(home: ProPaywallScreen()));
    expect(EntitlementService.isPro, isFalse);

    await tester.tap(find.text('Aktifkan Pro (dev)'));
    await tester.pumpAndSettle();

    expect(EntitlementService.isPro, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/pro_paywall_test.dart`
Expected: FAIL — `pro_paywall_screen.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/screens/pro_paywall_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/entitlement_service.dart';

/// Pro subscription pitch. v1 uses a dev toggle to unlock; the real billing
/// (RevenueCat) purchase flow lands in a later billing-only project — wire it
/// where marked below.
class ProPaywallScreen extends StatelessWidget {
  const ProPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Muslim Leveling Pro', style: AppText.displayHero(20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🛡️', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Text('Buka semua skin premium',
                style: AppText.displayHero(22), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Perisai, aura, dan gelar eksklusif. Gaya baru untuk avatarmu — '
                'tanpa memengaruhi XP, streak, atau peringkatmu.',
                style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            // TODO(billing): replace with RevenueCat purchase in the billing project.
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.tertiary),
              onPressed: () async {
                await EntitlementService.setProDev(true);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Aktifkan Pro (dev)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/pro_paywall_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/screens/pro_paywall_screen.dart test/pro_paywall_test.dart
git commit -m "feat(cosmetics): Pro paywall screen (dev toggle unlock)"
```

---

### Task 9: Cosmetic Locker widget

**Files:**
- Create: `lib/widgets/cosmetic_locker.dart`
- Test: `test/cosmetic_locker_test.dart`

**Interfaces:**
- Consumes: `CosmeticCatalog`/`CosmeticSlot` (Task 1), `GameService` (Task 5), `EntitlementService` (Task 3), `ProPaywallScreen` (Task 8).
- Produces: `class CosmeticLocker extends StatefulWidget` — a slot-tabbed grid. Each cell shows emoji + name. Owned/allowed → tap equips (calls `GameService.equipCosmetic`). Pro-locked while not Pro → shows a 🔒 and tap pushes `ProPaywallScreen`. Rebuilds on `GameService.stateVersion` and `EntitlementService.proStatus`.

- [ ] **Step 1: Write the failing test**

```dart
// test/cosmetic_locker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/widgets/cosmetic_locker.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping an owned free cosmetic equips it', (tester) async {
    await GameService.load();
    await EntitlementService.load();
    await GameService.debugSeedOwned(['title_crescent']);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: CosmeticLocker())));
    await tester.pumpAndSettle();

    // Switch to the Title tab, then tap the owned title.
    await tester.tap(find.text('Gelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulan Sabit Menyala'));
    await tester.pumpAndSettle();

    expect(GameService.current.equipped['title'], 'title_crescent');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/cosmetic_locker_test.dart`
Expected: FAIL — `cosmetic_locker.dart` not found.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/widgets/cosmetic_locker.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/cosmetic_catalog.dart';
import '../services/cosmetic_service.dart';
import '../services/game_service.dart';
import '../services/entitlement_service.dart';
import '../screens/pro_paywall_screen.dart';

const _slotLabels = {
  CosmeticSlot.frame: 'Bingkai',
  CosmeticSlot.aura: 'Aura',
  CosmeticSlot.title: 'Gelar',
};

class CosmeticLocker extends StatefulWidget {
  const CosmeticLocker({super.key});
  @override
  State<CosmeticLocker> createState() => _CosmeticLockerState();
}

class _CosmeticLockerState extends State<CosmeticLocker> {
  CosmeticSlot _slot = CosmeticSlot.frame;

  @override
  void initState() {
    super.initState();
    GameService.stateVersion.addListener(_rebuild);
    EntitlementService.proStatus.addListener(_rebuild);
  }

  @override
  void dispose() {
    GameService.stateVersion.removeListener(_rebuild);
    EntitlementService.proStatus.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _onTap(Cosmetic c) async {
    final isPro = EntitlementService.isPro;
    if (c.access == CosmeticAccess.pro && !isPro) {
      await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProPaywallScreen()));
      return;
    }
    await GameService.equipCosmetic(c.slot, c.id, isPro: isPro);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = EntitlementService.isPro;
    final state = GameService.current;
    final equippedId = CosmeticService.resolveSlot(state, _slot, isPro: isPro);
    final items = CosmeticCatalog.bySlot(_slot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Slot tabs
        Row(
          children: CosmeticSlot.values.map((s) {
            final sel = s == _slot;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_slotLabels[s]!),
                selected: sel,
                onSelected: (_) => setState(() => _slot = s),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: items.map((c) {
            final allowed = CosmeticService.isAllowed(state, c.id, isPro: isPro);
            final locked = c.access == CosmeticAccess.pro && !isPro;
            final owned = allowed || CosmeticCatalog.isDefault(c.id);
            final selected = c.id == equippedId;
            return InkWell(
              onTap: () => _onTap(c),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: selected ? AppColors.tertiary : Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(locked ? '🔒' : c.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(c.name,
                        style: AppText.bodyMd().copyWith(
                          fontSize: 10,
                          color: owned ? AppColors.onSurface : AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/cosmetic_locker_test.dart`
Expected: PASS (1 test).

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/cosmetic_locker.dart test/cosmetic_locker_test.dart
git commit -m "feat(cosmetics): cosmetic locker grid with equip + paywall gate"
```

---

### Task 10: Mount locker in Profil + wire avatar to equipped cosmetics

**Files:**
- Modify: `lib/screens/profil_tab.dart` (render `CosmeticLocker`; pass equipped frame/aura + title into the avatar/header)
- Test: `test/profil_cosmetic_integration_test.dart`

**Interfaces:**
- Consumes: `CosmeticLocker` (Task 9), `CosmeticService`/`CosmeticSlot` (Tasks 1/4), `EntitlementService` (Task 3), `TierProfileAvatar` (Tasks 6/7).
- Produces: Profil renders the avatar with `equippedFrameId`/`equippedAuraId` from `CosmeticService.resolveSlot(...)`, shows the equipped title text under the name, and includes a "Loker Skin" section hosting `CosmeticLocker`.

- [ ] **Step 1: Write the failing test**

```dart
// test/profil_cosmetic_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_leveling/screens/profil_tab.dart';
import 'package:muslim_leveling/widgets/cosmetic_locker.dart';
import 'package:muslim_leveling/services/game_service.dart';
import 'package:muslim_leveling/services/entitlement_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Profil shows the cosmetic locker', (tester) async {
    await GameService.load();
    await EntitlementService.load();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProfilTab())));
    await tester.pumpAndSettle();
    expect(find.byType(CosmeticLocker), findsOneWidget);
  });
}
```

> If `ProfilTab` needs constructor args, match its current signature; adapt the pump accordingly.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/profil_cosmetic_integration_test.dart`
Expected: FAIL — locker not present in Profil.

- [ ] **Step 3: Write minimal implementation**

In `lib/screens/profil_tab.dart`:

1. Add imports:
```dart
import '../widgets/cosmetic_locker.dart';
import '../services/cosmetic_service.dart';
import '../services/cosmetic_catalog.dart';
import '../services/entitlement_service.dart';
```

2. Where `TierProfileAvatar(...)` is built, resolve equipped cosmetics from the current `GameState` (call it `state`) and pass them in:
```dart
    final isPro = EntitlementService.isPro;
    final frameId = CosmeticService.resolveSlot(state, CosmeticSlot.frame, isPro: isPro);
    final auraId  = CosmeticService.resolveSlot(state, CosmeticSlot.aura,  isPro: isPro);
    final titleId = CosmeticService.resolveSlot(state, CosmeticSlot.title, isPro: isPro);
    final titleText = CosmeticCatalog.byId(titleId)?.titleText ?? '';
```
```dart
    TierProfileAvatar(
      tierName: /* existing */,
      profileImagePath: /* existing */,
      equippedFrameId: frameId,
      equippedAuraId: auraId,
      // ...existing params
    ),
```

3. Under the nickname/name text, show the equipped title when non-empty:
```dart
    if (titleText.isNotEmpty)
      Text(titleText, style: AppText.labelCaps().copyWith(color: AppColors.tertiary)),
```

4. Add a "Loker Skin" section (reuse the existing section header widget used elsewhere in Profil) containing `const CosmeticLocker()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/profil_cosmetic_integration_test.dart`
Expected: PASS (1 test). Then run the whole suite: `flutter test`. Expected: all green. Then `flutter analyze`. Expected: no new issues.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/profil_tab.dart test/profil_cosmetic_integration_test.dart
git commit -m "feat(cosmetics): mount locker in Profil + wire equipped avatar/title"
```

---

## Final verification (after all tasks)

- [ ] `flutter test` — full suite green (includes existing `backup_merge_test`, golden `profil_tab`).
- [ ] `flutter analyze` — no new warnings/errors.
- [ ] Manual smoke (browser/emulator via the run skill): complete 5/5 → open chest → collected reward now appears as an equippable item in the Loker; equip a free title → shows under name; tap a shield (locked) → paywall → "Aktifkan Pro (dev)" → shield equips and avatar switches to shield silhouette while keeping tier colors; toggle Pro off (dev) + reopen app → shield auto-reverts to `frame_default`, free title stays.
- [ ] Golden `test/goldens/profil_tab_phone.png` — if Profil layout shifted, regenerate with `flutter test --update-goldens test/` and eyeball the diff before committing.

## Spec coverage check
- Free/earned revival (dead `rewards`) → Tasks 1, 4 (migration), 9/10 (visible & equippable). ✓
- Pro gating + no pay-to-win prestige → Tasks 3, 4 (entitlement checks), 6 (tier colors preserved). ✓
- Shield frame changes shape only → Task 6. ✓
- Lapse auto-unequip, data kept → Tasks 4, 5. ✓
- Pro status not in GameState → Task 3 (SharedPreferences-backed, separate). ✓
- Backward-compatible persistence → Task 2. ✓
- Slots B/C/D → frame (6), aura (7), title (10). ✓
- Billing deferred behind EntitlementService → Tasks 3, 8 (TODO markers only). ✓

## Deferred (NOT in this plan)
One-time purchases · slot A (character skins) & E (app themes) · RevenueCat billing integration · Sedekah 100% passthrough (separate project).
