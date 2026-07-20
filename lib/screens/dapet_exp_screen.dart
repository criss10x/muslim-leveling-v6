import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/game_service.dart';

/// Dapet EXP — celebration screen after claiming quiz XP (no level-up).
/// Mirrors the Naik Level victory screen but themed for the Belajar tab:
/// cyan accent, book badge, and progress toward the next level.
class DapetExpScreen extends StatelessWidget {
  final int xpGained;
  final String moduleTitle;
  final int score;

  const DapetExpScreen({
    super.key,
    required this.xpGained,
    required this.moduleTitle,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final state = GameService.current;
    final info = GameService.getLevelInfo(state.xp);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppColors.tertiary.withValues(alpha: 0.1),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _badge(),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 250),
                    child: Text(
                      'DAPET EXP!',
                      textAlign: TextAlign.center,
                      style: AppText.displayHero(40).copyWith(
                        color: AppColors.tertiary,
                        shadows: [
                          Shadow(
                            color: AppColors.tertiary.withValues(alpha: 0.6),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Entrance(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Kamu menyelesaikan quiz $moduleTitle!',
                      textAlign: TextAlign.center,
                      style: AppText.bodyLg().copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 550),
                    child: _rewards(info),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 700),
                    child: _levelProgress(info),
                  ),
                  const Spacer(),
                  Entrance(
                    delay: const Duration(milliseconds: 850),
                    child: HeroButton(
                      label: 'KEMBALI',
                      trailingIcon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: ConfettiBurst(particleCount: 50)),
        ],
      ),
    );
  }

  Widget _badge() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppColors.tertiaryFixed, AppColors.tertiaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiary.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          Icons.auto_stories,
          color: AppColors.background,
          size: 72,
        ),
      ),
    );
  }

  Widget _rewards(LevelInfo info) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _rewardChip('+$xpGained', 'XP', AppColors.primary, Icons.bolt),
        _rewardChip('$score%', 'Skor Quiz', AppColors.tertiary, Icons.quiz),
        _rewardChip('Lv ${info.level}', 'Level', AppColors.secondaryFixed, Icons.trending_up),
      ],
    );
  }

  Widget _rewardChip(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: AppText.headlineMd().copyWith(color: color, fontSize: 20)),
            ),
          ),
          Text(
            label,
            style: AppText.labelCaps().copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelProgress(LevelInfo info) {
    final progress = info.xpNeededForNextLevel > 0
        ? info.xpInCurrentLevel / info.xpNeededForNextLevel
        : 0.0;
    final xpToNext = info.xpNeededForNextLevel - info.xpInCurrentLevel;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.tertiary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PROGRESS LEVEL',
            textAlign: TextAlign.center,
            style: AppText.labelCaps().copyWith(color: AppColors.tertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level ${info.level}',
                  style: AppText.titleLg().copyWith(fontSize: 16)),
              Text('${info.xpInCurrentLevel} / ${info.xpNeededForNextLevel} XP',
                  style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NeonProgressBar(progress: progress, leadingGlow: true, height: 10),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$xpToNext XP lagi menuju Level ${info.level + 1}',
            textAlign: TextAlign.center,
            style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
