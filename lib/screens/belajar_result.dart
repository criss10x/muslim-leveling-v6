import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'belajar_tab.dart';

/// Belajar Result — victory screen, big score, rewards, back-to-hub CTA.
class BelajarResultScreen extends StatelessWidget {
  final int correct;
  final int total;
  const BelajarResultScreen({
    super.key,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (correct / total * 100).round();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 100,
                    ),
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
                  const SizedBox(height: AppSpacing.lg),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [AppColors.primary, AppColors.tertiary],
                    ).createShader(rect),
                    child: Text(
                      'Modul Selesai!',
                      style: AppText.displayHero(40).copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pengetahuanmu semakin bertambah.',
                    style: AppText.bodyLg().copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'HASIL QUIZ',
                          style: AppText.labelCaps().copyWith(
                            color: AppColors.secondaryFixed,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '$pct%',
                          style: AppText.displayHero(40).copyWith(
                            color: AppColors.secondaryFixed,
                            shadows: [
                              Shadow(
                                color: AppColors.secondaryFixed.withValues(alpha: 0.6),
                                blurRadius: 25,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '$correct/$total Benar',
                                style: AppText.titleLg().copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppColors.tertiaryContainer,
                          size: 24,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '+200 XP',
                          style: AppText.headlineMd(),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Diperoleh',
                            style: AppText.labelCaps().copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  HeroButton(
                    label: 'KEMBALI KE HUB',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const BelajarTab()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GhostButton(
                    label: 'Coba Lagi',
                    icon: Icons.replay,
                    color: AppColors.tertiaryContainer,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondaryFixed, AppColors.secondaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryFixed.withValues(alpha: 0.5),
            blurRadius: 40,
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium,
        color: AppColors.onSecondary,
        size: 56,
      ),
    );
  }
}
