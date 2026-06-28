import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Profil Pejuang — hero header, stats grid, achievements, settings rows.
class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(top: AppSpacing.md, bottom: 100),
          children: [
            _hero(context),
            const SizedBox(height: AppSpacing.lg),
            _stats(),
            const SizedBox(height: AppSpacing.lg),
            _badges(),
            const SizedBox(height: AppSpacing.lg),
            _settings(),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryContainer, AppColors.secondaryFixed],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryFixed.withValues(alpha: 0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  color: AppColors.onSecondaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PejuangSunnah',
                      style: AppText.headlineMd().copyWith(fontSize: 20),
                    ),
                    Text(
                      'Muslim Warrior III',
                      style: AppText.labelCaps().copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                    Text(
                      'Bergabung sejak Maret 2024',
                      style: AppText.bodyMd().copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Lvl', '12', AppColors.primary),
              _miniStat('XP', '750', AppColors.tertiary),
              _miniStat('Streak', '7', AppColors.secondaryFixed),
              _miniStat('Badge', '14', AppColors.secondaryContainer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppText.headlineMd().copyWith(color: color, fontSize: 22)),
        Text(
          label,
          style: AppText.labelCaps().copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        _statCard('Sholat Selesai', '127', 'dari 150', Icons.mosque, AppColors.primary),
        _statCard('Tilawah', '8.5', 'juz', Icons.menu_book, AppColors.tertiary),
        _statCard('Sedekah', 'Rp 850K', 'bulan ini', Icons.volunteer_activism, AppColors.secondaryFixed),
        _statCard('Puasa Sunnah', '12', 'hari', Icons.nightlight, AppColors.tertiaryContainer),
      ],
    );
  }

  Widget _statCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppText.labelCaps().copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: AppText.headlineMd().copyWith(color: color, fontSize: 20)),
          Text(
            sub,
            style: AppText.bodyMd().copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badges() {
    final badges = [
      ('7-Day Streak', Icons.local_fire_department, AppColors.secondaryFixed, true),
      ('Quran Reader', Icons.menu_book, AppColors.primary, true),
      ('Early Bird', Icons.wb_twilight, AppColors.tertiary, true),
      ('Generous', Icons.volunteer_activism, AppColors.secondaryContainer, false),
    ];
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACHIEVEMENTS',
            style: AppText.labelCaps().copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: badges.map((b) {
              return Expanded(
                child: Opacity(
                  opacity: b.$4 ? 1.0 : 0.3,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: b.$3.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: b.$3.withValues(alpha: 0.4)),
                          boxShadow: b.$4
                              ? [
                                  BoxShadow(
                                    color: b.$3.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(b.$2, color: b.$3, size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelCaps().copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _settings() {
    final rows = <_SettingRow>[
      _SettingRow('Pengaturan Akun', Icons.person_outline),
      _SettingRow('Notifikasi', Icons.notifications_outlined),
      _SettingRow('Tema & Tampilan', Icons.palette_outlined),
      _SettingRow('Privasi & Data', Icons.lock_outline),
      _SettingRow('Tentang Aplikasi', Icons.info_outline),
      _SettingRow('Keluar', Icons.logout, color: AppColors.error),
    ];
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          r.icon,
                          color: r.color ?? AppColors.onSurface,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            r.title,
                            style: AppText.bodyLg().copyWith(
                              color: r.color ?? AppColors.onSurface,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  color: AppColors.outlineVariant,
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingRow {
  final String title;
  final IconData icon;
  final Color? color;
  _SettingRow(this.title, this.icon, {this.color});
}
