import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Jadwal Sholat — hero icons edition. Next prayer + daily schedule list.
class JadwalTab extends StatelessWidget {
  const JadwalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: AppSpacing.md),
            _pill(),
            const SizedBox(height: AppSpacing.xs),
            _header(),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _qiblaButton(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _nextPrayerCard(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _schedule(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _monthlyTracker(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'JADWAL SHOLAT',
          style: AppText.labelCaps().copyWith(
            color: AppColors.secondaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.onSurface, size: 32),
              const SizedBox(width: 4),
              Text('Waktu Sholat', style: AppText.displayHero(32)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '15 Ramadhan 1445H',
                style: AppText.bodyMd().copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('•', style: TextStyle(color: AppColors.outlineVariant)),
              ),
              const Icon(Icons.location_on, size: 14, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Jakarta, Indonesia',
                style: AppText.bodyMd().copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qiblaButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondaryContainer, AppColors.secondaryFixed],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl - 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore, size: 24, color: AppColors.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Kompas Kiblat',
              style: AppText.titleLg().copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward, color: AppColors.onSecondaryContainer),
          ],
        ),
      ),
    );
  }

  Widget _nextPrayerCard() {
    return NeonPulse(
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELANJUTNYA',
                      style: AppText.labelCaps().copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text('Ashar', style: AppText.headlineLg()),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBright.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        size: 14,
                        color: AppColors.secondaryFixed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '45m lagi',
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryFixed],
                  ).createShader(rect),
                  child: Text(
                    '15:12',
                    style: AppText.displayHero(40).copyWith(color: Colors.white),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _schedule() {
    final items = [
      ('Subuh', '04:32', Icons.wb_twilight, true, false),
      ('Dzuhur', '12:00', Icons.wb_sunny, true, false),
      ('Ashar', '15:12', Icons.wb_cloudy, false, true),
      ('Maghrib', '18:02', Icons.wb_twilight, false, false),
      ('Isya', '19:15', Icons.nightlight, false, false),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JADWAL HARI INI',
          style: AppText.labelCaps().copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _scheduleRow(it.$1, it.$2, it.$3, it.$4, it.$5),
            )),
      ],
    );
  }

  Widget _scheduleRow(
    String name,
    String time,
    IconData icon,
    bool completed,
    bool active,
  ) {
    final color = active
        ? AppColors.primary
        : (completed ? AppColors.onSurfaceVariant : AppColors.onSurface);
    return Opacity(
      opacity: completed ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: active
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.2),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              name,
              style: AppText.titleLg().copyWith(
                color: color,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (completed) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _monthlyTracker() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STREAK BULANAN',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(28, (i) {
              final filled = i < 12;
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '12/28 hari istiqomah',
            style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
