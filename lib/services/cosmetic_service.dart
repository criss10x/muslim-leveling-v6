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
