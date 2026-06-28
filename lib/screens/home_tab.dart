import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'naik_level_screen.dart';

/// Home / Dashboard Utama — rank, XP, ritual rings, daily quests, side quest.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 100),
          children: [
            _appBar(context),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _heroRank(),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(child: _countdownCard()),
                  const SizedBox(width: AppSpacing.md),
                  _streakCard(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ritualRings(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _prayerQuests(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _bonusQuest(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _sideQuest(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _dailyBento(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _levelUpCTA(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainer,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.shield,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.primary, AppColors.tertiary],
            ).createShader(rect),
            child: Text(
              'MUSLIM LEVELING',
              style: AppText.headlineMd().copyWith(
                color: Colors.white,
                fontSize: 18,
                height: 1.0,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _heroRank() {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT RANK',
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Muslim Warrior III',
                        style: AppText.headlineMd().copyWith(
                          color: AppColors.primary,
                          shadows: [
                            Shadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: AppColors.secondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '7 Hari',
                          style: AppText.labelCaps(),
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
                  Text(
                    'XP PROGRESS',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '750 / 1000',
                    style: AppText.bodyMd().copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const NeonProgressBar(progress: 0.75),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '250 XP to Next Rank',
                  style: AppText.labelCaps().copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countdownCard() {
    return NeonPulse(
      color: AppColors.primary,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXT MATCH',
              style: AppText.labelCaps().copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ASHAR',
              style: AppText.headlineMd().copyWith(color: AppColors.tertiary),
            ),
            const SizedBox(height: 4),
            const Text(
              '00:42:15',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                color: AppColors.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard() {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(
            color: AppColors.secondaryFixed,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryFixed.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.secondaryFixed,
          ),
          const SizedBox(height: 4),
          Text(
            '7',
            style: AppText.headlineMd().copyWith(
              color: AppColors.secondaryFixed,
            ),
          ),
          Text(
            'HARI\nSTREAK',
            textAlign: TextAlign.center,
            style: AppText.labelCaps().copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ritualRings() {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'RITUAL RINGS',
                style: AppText.labelCaps().copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _RingsPainter(),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _ringStat('WAJIB', '3/5', AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    _ringStat('SUNNAH', '2/8', AppColors.secondaryFixed),
                    const SizedBox(height: AppSpacing.sm),
                    _ringStat('TILAWAH', 'Belum', AppColors.tertiary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ringStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.labelCaps().copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            Text(value, style: AppText.titleLg().copyWith(color: color)),
          ],
        ),
      ],
    );
  }

  Widget _prayerQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified, color: AppColors.primary, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'QUEST SHOLAT HARI INI',
              style: AppText.labelCaps().copyWith(color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _prayerRow('Subuh', Icons.check_circle, 'COMPLETED', AppColors.primary, completed: true),
        const SizedBox(height: AppSpacing.xs),
        _prayerRow('Dzuhur', Icons.check_circle, 'COMPLETED', AppColors.primary, completed: true),
        const SizedBox(height: AppSpacing.xs),
        _prayerRow('Ashar', Icons.radio_button_checked, 'ACTIVE NOW', AppColors.primary, active: true),
        const SizedBox(height: AppSpacing.xs),
        _prayerRow('Maghrib', Icons.lock, 'LOCKED', AppColors.onSurfaceVariant, locked: true),
        const SizedBox(height: AppSpacing.xs),
        _prayerRow('Isya', Icons.lock, 'LOCKED', AppColors.onSurfaceVariant, locked: true),
      ],
    );
  }

  Widget _prayerRow(
    String name,
    IconData icon,
    String status,
    Color color, {
    bool completed = false,
    bool active = false,
    bool locked = false,
  }) {
    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: active
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(
              name,
              style: AppText.titleLg().copyWith(
                color: active
                    ? AppColors.primary
                    : (locked ? AppColors.onSurfaceVariant : AppColors.onBackground),
              ),
            ),
            const Spacer(),
            Text(
              status,
              style: AppText.labelCaps().copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bonusQuest() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.secondaryFixed, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'BONUS QUEST — SUNNAH',
              style: AppText.labelCaps().copyWith(color: AppColors.secondaryFixed),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _bonusRow('Dhuha', 'Window: 08:00 - 11:00', Icons.wb_sunny, AppColors.secondaryFixed, locked: true),
        const SizedBox(height: AppSpacing.xs),
        _bonusRow('Rawatib Qobliyah Dzuhur', '4 Rakaat', Icons.history, AppColors.secondaryFixed, completed: true),
      ],
    );
  }

  Widget _bonusRow(
    String name,
    String sub,
    IconData icon,
    Color color, {
    bool locked = false,
    bool completed = false,
  }) {
    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.bodyLg()),
                  Text(
                    sub,
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (completed)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.lock_clock, color: AppColors.outline, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _sideQuest(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                '📜 SIDE QUEST',
                style: AppText.labelCaps().copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.tertiary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiary.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppColors.tertiary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tilawah & Dzikir',
                      style: AppText.headlineMd().copyWith(fontSize: 18),
                    ),
                    Text(
                      'Selesaikan juz harianmu',
                      style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: AppColors.onTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dailyBento() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.0,
      children: [
        _zikirTile('SUBHANALLAH', '33', AppColors.primary, '+1 XP', Icons.refresh),
        _zikirTile('ALHAMDULILLAH', '33', AppColors.tertiary, '+1 XP', Icons.refresh),
        _zikirTile('ALLAHU AKBAR', '34', AppColors.secondaryFixed, '+1 XP', Icons.refresh),
        _zikirTile('DZIKIR PAGI', '5/8', AppColors.primary, 'MENU', Icons.arrow_forward),
      ],
    );
  }

  Widget _zikirTile(String label, String count, Color color, String cta, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppText.labelCaps().copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: AppText.displayHero(32).copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 4),
              Text(cta, style: AppText.labelCaps().copyWith(color: color, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelUpCTA(BuildContext context) {
    return HeroButton(
      label: 'TRIGGER LEVEL UP',
      trailingIcon: Icons.auto_awesome,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NaikLevelScreen()),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [56.0, 42.0, 28.0];
    final colors = [AppColors.primary, AppColors.secondaryFixed, AppColors.tertiary];
    final progresses = [0.6, 0.25, 0.0];

    for (var i = 0; i < radii.length; i++) {
      final paintBg = Paint()
        ..color = AppColors.surfaceContainerHighest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(center, radii[i], paintBg);

      if (progresses[i] > 0) {
        final paintFg = Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;
        final sweep = 2 * 3.14159 * (1 - progresses[i]);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radii[i]),
          -3.14159 / 2,
          2 * 3.14159 - sweep,
          false,
          paintFg,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
