import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/game_service.dart';

/// Naik Level — victory celebration, rank-up screen, full-bleed reward.
/// Now supports multi-level-up sequences: shows one level-up at a time.
class NaikLevelScreen extends StatefulWidget {
  final int? xpGained;
  final int levelsGained;

  const NaikLevelScreen({super.key, this.xpGained, this.levelsGained = 1});

  @override
  State<NaikLevelScreen> createState() => _NaikLevelScreenState();
}

class _NaikLevelScreenState extends State<NaikLevelScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final state = GameService.current;
    final info = GameService.getLevelInfo(state.xp);
    final currentLevel = info.level;
    final startLevel = currentLevel - widget.levelsGained + 1;
    final shownLevel = startLevel + _step;
    final rankTitle = GameService.getRankTitle(shownLevel);
    final isLast = _step >= widget.levelsGained - 1;

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
                    AppColors.primary.withValues(alpha: 0.1),
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
                  _badge(context),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 250),
                    child: Text(
                      'NAIK LEVEL!',
                      textAlign: TextAlign.center,
                      style: AppText.displayHero(40).copyWith(
                        color: AppColors.secondaryFixed,
                        shadows: [
                          Shadow(
                            color: AppColors.secondaryFixed.withValues(alpha: 0.6),
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
                      'Kamu mencapai $rankTitle — Level $shownLevel',
                      textAlign: TextAlign.center,
                      style: AppText.bodyLg().copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (widget.levelsGained > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_step + 1} / ${widget.levelsGained}',
                      style: AppText.labelCaps().copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 550),
                    child: _rewards(shownLevel, rankTitle),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Entrance(
                    delay: const Duration(milliseconds: 700),
                    child: _unlocked(shownLevel),
                  ),
                  const Spacer(),
                  Entrance(
                    delay: const Duration(milliseconds: 850),
                    child: HeroButton(
                      label: isLast ? 'KEMBALI' : 'LANJUT',
                      trailingIcon: isLast ? Icons.arrow_back : Icons.arrow_forward,
                      onPressed: () {
                        if (isLast) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _step += 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // celebratory confetti raining over everything
          const Positioned.fill(child: ConfettiBurst(particleCount: 70)),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(_step),
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [AppColors.secondaryFixed, AppColors.secondaryContainer],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryFixed.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium,
          color: AppColors.onSecondaryContainer,
          size: 80,
        ),
      ),
    );
  }

  Widget _rewards(int shownLevel, String rankTitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _rewardChip('+${widget.xpGained ?? 0}', 'XP', AppColors.primary, Icons.bolt),
        _rewardChip('Lv $shownLevel', 'Level', AppColors.secondaryFixed, Icons.trending_up),
        _rewardChip('NEW', rankTitle, AppColors.tertiary, Icons.auto_awesome),
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

  Widget _unlocked(int shownLevel) {
    final info = GameService.getLevelInfo(GameService.current.xp);
    final xpToNext = info.xpNeededForNextLevel - info.xpInCurrentLevel;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'STATUS TERBARU',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _unlockRow('Total XP', '${GameService.current.xp}', AppColors.primary),
          _unlockRow('XP di Level ${info.level}', '${info.xpInCurrentLevel} / ${info.xpNeededForNextLevel}', AppColors.tertiary),
          _unlockRow('Menuju Level ${info.level + 1}', '$xpToNext XP', AppColors.secondaryFixed),
        ],
      ),
    );
  }

  Widget _unlockRow(String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyLg().copyWith(fontWeight: FontWeight.w600)),
                Text(
                  sub,
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_open, color: color, size: 18),
        ],
      ),
    );
  }
}
