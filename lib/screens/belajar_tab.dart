import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'belajar_article.dart';

/// Belajar / Learning Hub — modules list with category tabs and progress.
class BelajarTab extends StatelessWidget {
  const BelajarTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: 100, top: AppSpacing.md),
          children: [
            Text(
              'LEARNING HUB',
              style: AppText.labelCaps().copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text('Belajar Bareng', style: AppText.headlineLg().copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              'Tingkatkan ilmu, raih lebih banyak XP.',
              style: AppText.bodyMd().copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _progressCard(),
            const SizedBox(height: AppSpacing.lg),
            _categoryTabs(),
            const SizedBox(height: AppSpacing.md),
            _moduleList(context),
          ],
        ),
      ),
    );
  }

  Widget _progressCard() {
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Santri Digital', style: AppText.titleLg()),
                  Text(
                    '4/16 modul selesai',
                    style: AppText.labelCaps().copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(
                    color: AppColors.secondaryFixed.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryFixed.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.secondaryFixed,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.25,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tabChip('Akidah', true),
          _tabChip('Rukun Islam', false),
          _tabChip('Praktik Ibadah', false),
          _tabChip('Akhlak', false),
        ],
      ),
    );
  }

  Widget _tabChip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.surfaceContainerHigh
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: active
              ? AppColors.outline
              : AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: AppText.labelCaps().copyWith(
          color: active ? AppColors.primary : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _moduleList(BuildContext context) {
    final mods = [
      _Mod('Mengenal Allah', 'Selesai', '+200 XP', AppColors.primary, true, false),
      _Mod('Sifat-sifat Wajib', '10m', '+200 XP', AppColors.tertiaryContainer, false, true),
      _Mod('Sifat-sifat Mustahil', '12m', '+250 XP', null, false, false),
      _Mod('Rukun Iman', '8m', '+150 XP', null, false, false),
      _Mod('Asmaul Husna', '15m', '+300 XP', null, false, false),
    ];
    return Column(
      children: mods.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: _moduleCard(context, m),
      )).toList(),
    );
  }

  Widget _moduleCard(BuildContext context, _Mod m) {
    final isLocked = !m.completed && !m.unlocked;
    return Opacity(
      opacity: isLocked ? 0.75 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: isLocked
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BelajarArticleScreen(),
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: m.completed
                  ? AppColors.surfaceContainer
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: m.unlocked
                  ? Border.all(color: AppColors.tertiaryContainer.withValues(alpha: 0.6))
                  : Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: m.completed
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (m.unlocked
                            ? AppColors.tertiaryContainer.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: m.completed
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (m.unlocked
                              ? AppColors.tertiaryContainer.withValues(alpha: 0.3)
                              : AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Icon(
                    m.completed
                        ? Icons.task_alt
                        : (m.unlocked ? Icons.menu_book : Icons.lock),
                    color: m.completed
                        ? AppColors.primary
                        : (m.unlocked
                            ? AppColors.tertiaryContainer
                            : AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title, style: AppText.titleLg().copyWith(fontSize: 18)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (m.completed) ...[
                            const Icon(
                              Icons.military_tech,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.status,
                              style: AppText.labelCaps().copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.tertiaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              m.status,
                              style: AppText.labelCaps().copyWith(
                                color: AppColors.tertiaryContainer,
                              ),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(color: AppColors.outlineVariant),
                            ),
                          ),
                          Text(
                            m.xp,
                            style: AppText.labelCaps().copyWith(
                              color: AppColors.secondaryFixed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (m.unlocked && !m.completed)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.tertiaryContainer,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Mod {
  final String title;
  final String status;
  final String xp;
  final Color? accent;
  final bool completed;
  final bool unlocked;
  _Mod(this.title, this.status, this.xp, this.accent, this.completed, this.unlocked);
}
