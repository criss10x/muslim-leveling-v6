import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'dashboard_shell.dart';

/// Naik Level — victory celebration, rank-up screen, full-bleed reward.
class NaikLevelScreen extends StatelessWidget {
  const NaikLevelScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text(
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kamu mencapai Muslim Warrior IV',
                    textAlign: TextAlign.center,
                    style: AppText.bodyLg().copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _rewards(),
                  const SizedBox(height: AppSpacing.xl),
                  _unlocked(),
                  const Spacer(),
                  HeroButton(
                    label: 'KEMBALI KE DASHBOARD',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DashboardShell(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context) {
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

  Widget _rewards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _rewardChip('+500', 'XP', AppColors.primary, Icons.bolt),
        _rewardChip('+1', 'Badge', AppColors.secondaryFixed, Icons.workspace_premium),
        _rewardChip('NEW', 'Title', AppColors.tertiary, Icons.auto_awesome),
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
          Text(value, style: AppText.headlineMd().copyWith(color: color, fontSize: 20)),
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

  Widget _unlocked() {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'YANG BARU TERBUKA',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _unlockRow('Modul Premium', 'Pelajaran lanjutan tier Mythic', AppColors.tertiary),
          _unlockRow('Avatar Mythic', 'Skin karakter eksklusif', AppColors.secondaryFixed),
          _unlockRow('Challenge Mingguan', 'Misi khusus rank Warrior IV', AppColors.primary),
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
