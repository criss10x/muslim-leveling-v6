import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'character_creation.dart';

/// Welcome Pejuang — onboarding hero with 3 feature cards + start button.
class WelcomePejuangScreen extends StatelessWidget {
  const WelcomePejuangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AmbientBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.lg),
                _header(),
                const SizedBox(height: AppSpacing.xl),
                _featureCard(
                  icon: Icons.mosque_outlined,
                  title: 'Quest Sholat',
                  description:
                      'Selesaikan quest sholat wajib & sunnah setiap hari untuk dapat XP dan menjaga streak.',
                  accent: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _featureCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Belajar yang Fun',
                  description:
                      'Pelajari materi Islam melalui artikel & quiz interaktif yang menyenangkan.',
                  accent: AppColors.tertiary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _featureCard(
                  icon: Icons.military_tech_outlined,
                  title: 'Badge & Achievement',
                  description:
                      'Kumpulkan badge dan capai rank tertinggi sebagai pejuang muslim.',
                  accent: AppColors.secondaryContainer,
                ),
                const SizedBox(height: AppSpacing.xl),
                HeroButton(
                  label: 'MULAI PETUALANGAN',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CharacterCreationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Fun way to 100% fokus istiqomah.',
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 30,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: 48,
            height: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [AppColors.onSurface, AppColors.onSurfaceVariant],
          ).createShader(rect),
          child: Text(
            'MUSLIM',
            style: AppText.displayHero(32).copyWith(
              color: Colors.white,
              height: 38 / 32,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            colors: [AppColors.primary, AppColors.tertiary],
          ).createShader(rect),
          child: Text(
            'LEVELING',
            style: AppText.displayHero(32).copyWith(
              color: Colors.white,
              height: 38 / 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, accent.withValues(alpha: 0)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleLg()),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppText.bodyMd().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
