import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import 'belajar_article.dart';

/// Belajar / Learning Hub — modules list with category tabs and progress.
/// Logic + content ported from V3 BelajarScreen.kt.
class BelajarTab extends StatefulWidget {
  const BelajarTab({super.key});
  @override
  State<BelajarTab> createState() => _BelajarTabState();
}

class _BelajarTabState extends State<BelajarTab> {
  int _selectedCat = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LearningService.load();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final completed = LearningService.completedCount;
    final total = LearningService.totalModules;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md)
                .copyWith(bottom: 100, top: AppSpacing.md),
            children: [
              Text('LEARNING HUB',
                  style: AppText.labelCaps().copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('Belajar Bareng', style: AppText.headlineLg().copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text('Tingkatkan ilmu, raih lebih banyak XP.',
                  style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.lg),
              _progressCard(completed, total),
              const SizedBox(height: AppSpacing.lg),
              _categoryTabs(),
              const SizedBox(height: AppSpacing.md),
              _moduleList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressCard(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Santri Digital', style: AppText.titleLg()),
                  Text('$completed/$total modul selesai',
                      style: AppText.labelCaps().copyWith(color: AppColors.primary)),
                ],
              ),
              Text('${(progress * 100).round()}%',
                  style: AppText.headlineMd().copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NeonProgressBar(progress: progress, leadingGlow: true),
        ],
      ),
    );
  }

  Widget _categoryTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LearningContent.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final cat = LearningContent.categories[i];
          final selected = i == _selectedCat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCat = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surfaceContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: selected
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.6))
                    : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: AppText.labelCaps().copyWith(
                          color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                          fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _moduleList(BuildContext context) {
    final cat = LearningContent.categories[_selectedCat];
    return Column(
      children: cat.modules.map((mod) {
        final unlocked = LearningService.isUnlocked(mod.id);
        final completed = LearningService.isCompleted(mod.id);
        final xpClaimed = LearningService.isXpClaimed(mod.id);
        final progress = LearningService.getProgress(mod.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _moduleCard(context, mod, unlocked, completed, xpClaimed, progress?.quizScore ?? 0),
        );
      }).toList(),
    );
  }

  Widget _moduleCard(BuildContext context, LearningModule mod, bool unlocked,
      bool completed, bool xpClaimed, int quizScore) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: completed
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: completed
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: unlocked
              ? () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BelajarArticleScreen(moduleId: mod.id),
                  )).then((_) => _load()); // refresh on return
                }
              : null,
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: completed ? AppColors.primary : AppColors.outlineVariant,
                    width: completed ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: unlocked
                      ? Text(mod.icon, style: const TextStyle(fontSize: 24))
                      : const Icon(Icons.lock, color: AppColors.onSurfaceVariant, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mod.title,
                        style: AppText.bodyLg().copyWith(
                            color: unlocked ? AppColors.onBackground : AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${mod.estimatedMinutes} min',
                            style: AppText.labelCaps().copyWith(
                                color: AppColors.onSurfaceVariant, fontSize: 10)),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.stars, size: 12, color: AppColors.secondaryFixed),
                        const SizedBox(width: 4),
                        Text(xpClaimed ? '✓ +${mod.xpReward} XP' : '+${mod.xpReward} XP',
                            style: AppText.labelCaps().copyWith(
                                color: xpClaimed
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.secondaryFixed,
                                fontSize: 10)),
                        if (completed) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text('Quiz: $quizScore%',
                              style: AppText.labelCaps().copyWith(
                                  color: AppColors.primary, fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle
                    : (unlocked ? Icons.arrow_forward_ios : Icons.lock_clock),
                color: completed
                    ? AppColors.primary
                    : (unlocked ? AppColors.onSurfaceVariant : AppColors.outline),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
