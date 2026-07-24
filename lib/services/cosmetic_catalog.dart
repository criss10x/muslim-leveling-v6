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
