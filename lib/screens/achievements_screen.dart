import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/achievement_service.dart';
import '../../widgets/achievement_medal.dart';
import '../../widgets/share_card.dart';

/// Galeri medali — dipisah dari tab Profil.
///
/// Sebelumnya 43 medali digelar dalam satu grid 4 kolom di tengah tab Profil:
/// profilnya jadi panjang, medalinya jadi kecil. Di sini medali dikelompokkan
/// per tier karena tangga rarity itu informasi nyata (seberapa langka, seberapa
/// jauh kamu melangkah), bukan sekadar pemisah visual. Progres per tier
/// menunjukkan di tangga mana kamu sedang mentok.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  static const _tierLabels = <AchievementTier, String>{
    AchievementTier.rookie: 'ROOKIE',
    AchievementTier.elite: 'ELITE',
    AchievementTier.gold: 'GOLD',
    AchievementTier.epic: 'EPIC',
    AchievementTier.legendary: 'LEGENDARY',
  };

  @override
  Widget build(BuildContext context) {
    final defs = AchievementService.defs;
    final unlocked = AchievementService.unlockedCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Entrance(child: _header(unlocked, defs.length)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  children: [
                    for (var i = 0; i < AchievementTier.values.length; i++)
                      Entrance(
                        delay: Duration(milliseconds: 120 + i * 60),
                        child: _tierSection(AchievementTier.values[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int unlocked, int total) {
    final pct = total == 0 ? 0.0 : unlocked / total;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PressableScale(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.onSurface, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GALERI MEDALI',
                        style: AppText.labelCaps().copyWith(
                            color: AppColors.secondaryFixed, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text('Achievements', style: AppText.displayHero(24)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$unlocked',
                  style: AppText.displayHero(20)
                      .copyWith(color: AppColors.secondaryFixed)),
              Text(' / $total medali terbuka',
                  style: AppText.bodyMd().copyWith(
                      color: AppColors.onSurfaceVariant, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.secondaryFixed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierSection(AchievementTier tier) {
    final defs =
        AchievementService.defs.where((d) => d.tier == tier).toList();
    if (defs.isEmpty) return const SizedBox.shrink();

    final got =
        defs.where((d) => AchievementService.isUnlocked(d.id)).length;
    final (accent, _) = tierColors(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        HudHeader(_tierLabels[tier]!,
            meta: '$got/${defs.length}', accent: accent),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.8,
          children: defs.map(_medal).toList(),
        ),
      ],
    );
  }

  Widget _medal(AchievementDef d) {
    final unlocked = AchievementService.isUnlocked(d.id);
    final (accent, _) = tierColors(d.tier);

    return PressableScale(
      onTap: () => showAchievementDetail(
        context,
        d,
        unlocked: unlocked,
        unlockedDate: AchievementService.unlockedDate(d.id),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              AchievementMedal(def: d, unlocked: unlocked, size: 72),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  d.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelCaps().copyWith(
                    fontSize: 9,
                    color: unlocked
                        ? accent
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          if (unlocked)
            Positioned(
              top: -2,
              right: -2,
              child: GestureDetector(
                onTap: () => showShareCard(context, d),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: accent.withValues(alpha: 0.5), width: 1),
                  ),
                  child: Icon(Icons.share, size: 11, color: accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
