import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Statistik Mingguan — bottom sheet that slides up over the dashboard.
class StatistikSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _StatistikContent(),
    );
  }
}

class _StatistikContent extends StatelessWidget {
  const _StatistikContent();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'STATISTIK MINGGUAN',
                style: AppText.labelCaps().copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(
                'Performa Pejuang',
                style: AppText.headlineLg().copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.lg),
              _kpis(),
              const SizedBox(height: AppSpacing.lg),
              _barChart(),
              const SizedBox(height: AppSpacing.lg),
              _heatmap(),
              const SizedBox(height: AppSpacing.lg),
              _ranking(),
            ],
          ),
        );
      },
    );
  }

  Widget _kpis() {
    return Row(
      children: [
        Expanded(child: _kpi('Total Sholat', '127', 'dari 175', AppColors.primary, Icons.mosque)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _kpi('Rata-rata', '4.5', '/hari', AppColors.tertiary, Icons.trending_up)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _kpi('Streak', '7', 'hari', AppColors.secondaryFixed, Icons.local_fire_department)),
      ],
    );
  }

  Widget _kpi(String title, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(top: BorderSide(color: color, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: AppText.headlineMd().copyWith(color: color, fontSize: 20)),
          Text(title, style: AppText.labelCaps().copyWith(fontSize: 10)),
          Text(
            sub,
            style: AppText.bodyMd().copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChart() {
    final days = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    final values = [0.9, 0.8, 0.6, 1.0, 0.7, 0.5, 0.85];
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHOLAT 7 HARI',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 100 * values[i],
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                // Light: bright fill → deep action. Dark: deep container → bright primary.
                                isLightTheme
                                    ? AppColors.primaryFixed
                                    : AppColors.primaryContainer,
                                AppColors.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          days[i],
                          style: AppText.labelCaps().copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatmap() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KONSISTENSI 30 HARI',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(30, (i) {
              final filled = (i % 4) != 0;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.primary.withValues(alpha: 0.3 + (i % 3) * 0.2)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _ranking() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RANKING PEJUANG',
            style: AppText.labelCaps().copyWith(color: AppColors.secondaryFixed),
          ),
          const SizedBox(height: AppSpacing.sm),
          _rankRow(1, 'Ahmad F.', '1240 XP', true),
          _rankRow(2, 'Siti A.', '1180 XP', false),
          _rankRow(3, 'PejuangSunnah', '750 XP', false, isYou: true),
          _rankRow(4, 'Budi S.', '690 XP', false),
          _rankRow(5, 'Dewi K.', '540 XP', false),
        ],
      ),
    );
  }

  Widget _rankRow(int rank, String name, String xp, bool isTop, {bool isYou = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
      decoration: BoxDecoration(
        color: isYou
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isYou
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop
                  ? AppColors.secondaryFixed
                  : AppColors.surfaceContainerHigh,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: AppText.labelCaps().copyWith(
                color: isTop ? AppColors.onSecondaryContainer : AppColors.onSurface,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: AppText.bodyLg().copyWith(
                fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
                color: isYou ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ),
          Text(
            xp,
            style: AppText.labelCaps().copyWith(
              color: AppColors.secondaryFixed,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
