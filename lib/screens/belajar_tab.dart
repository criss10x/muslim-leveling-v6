import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import '../../services/theme_service.dart';
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
    themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
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
      backgroundColor: Colors.transparent,
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

  /// Hero tab Belajar — aksen primary. Light: solid white card (no glow).
  /// Dark: soft gradient + glow, selaras hero Home/Jadwal.
  Widget _progressCard(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    final light = isLightTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: light ? AppColors.surfaceContainerLow : null,
        gradient: light
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.surfaceContainer.withValues(alpha: 0.7),
                ],
              ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: light ? 0.35 : 0.4),
        ),
        boxShadow: light
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SANTRI DIGITAL',
                      style: AppText.labelCaps().copyWith(color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text('$completed/$total modul selesai',
                      style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
              Text('${(progress * 100).round()}%',
                  style: AppText.displayHero(32).copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          NeonProgressBar(progress: progress, leadingGlow: true, height: 10),
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
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.pill),
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
    final catDone =
        cat.modules.where((m) => LearningService.isCompleted(m.id)).length;
    // "Frontier" = modul pertama yang kebuka tapi belum selesai — inilah
    // yang dapat hairline cyan (analog "berikutnya" di tab lain).
    final frontierId = cat.modules
        .firstWhereOrNull((m) =>
            LearningService.isUnlocked(m.id) && !LearningService.isCompleted(m.id))
        ?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HudHeader(cat.label.toUpperCase(), meta: '$catDone/${cat.modules.length}'),
        ...cat.modules.map((mod) {
          final unlocked = LearningService.isUnlocked(mod.id);
          final completed = LearningService.isCompleted(mod.id);
          final xpClaimed = LearningService.isXpClaimed(mod.id);
          final progress = LearningService.getProgress(mod.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _moduleCard(context, mod, unlocked, completed, xpClaimed,
                progress?.quizScore ?? 0, mod.id == frontierId),
          );
        }),
      ],
    );
  }

  Widget _moduleCard(BuildContext context, LearningModule mod, bool unlocked,
      bool completed, bool xpClaimed, int quizScore, bool isFrontier) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.4,
      child: PressableScale(
        onTap: unlocked
            ? () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BelajarArticleScreen(moduleId: mod.id),
                )).then((_) => _load()); // refresh on return
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isFrontier
                ? AppColors.tertiary.withValues(alpha: 0.06)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: isFrontier
                ? Border.all(color: AppColors.tertiary.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Center(
                  child: unlocked
                      ? Text(mod.icon, style: const TextStyle(fontSize: 26))
                      : Icon(Icons.lock, color: AppColors.onSurfaceVariant, size: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mod.title,
                        style: AppText.bodyLg().copyWith(
                            color: completed
                                ? AppColors.onSurfaceVariant
                                : AppColors.onBackground)),
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
                    : (isFrontier
                        ? AppColors.tertiary
                        : (unlocked ? AppColors.onSurfaceVariant : AppColors.outline)),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
