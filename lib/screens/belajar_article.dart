import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import 'belajar_quiz.dart';

/// Article reader — renders ArticleBlock content from V3 LearningContent.
class BelajarArticleScreen extends StatefulWidget {
  final String moduleId;
  const BelajarArticleScreen({super.key, required this.moduleId});
  @override
  State<BelajarArticleScreen> createState() => _BelajarArticleScreenState();
}

class _BelajarArticleScreenState extends State<BelajarArticleScreen> {
  late final LearningModule _module;
  late final List<ArticleBlock> _blocks;
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _module = LearningContent.getAllModulesOrdered()
        .where((m) => m.id == widget.moduleId)
        .first;
    _blocks = LearningContent.getArticle(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            // Reading progress bar
            LinearProgressIndicator(
              value: _scrollProgress,
              minHeight: 2,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollUpdateNotification && n.metrics.maxScrollExtent > 0) {
                    setState(() {
                      _scrollProgress = n.metrics.pixels / n.metrics.maxScrollExtent;
                    });
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md).copyWith(bottom: 120),
                  itemCount: _blocks.length,
                  itemBuilder: (_, i) => _renderBlock(_blocks[i]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomCta(context),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_module.icon}  ${_module.title}',
                    style: AppText.titleLg().copyWith(fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${_module.estimatedMinutes} min baca • +${_module.xpReward} XP',
                    style: AppText.labelCaps().copyWith(
                        color: AppColors.onSurfaceVariant, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBlock(ArticleBlock block) {
    if (block is Heading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(block.text,
            style: AppText.headlineLg().copyWith(fontSize: 22, color: AppColors.primary)),
      );
    }
    if (block is Subheading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
        child: Text(block.text,
            style: AppText.titleLg().copyWith(fontSize: 16, color: AppColors.tertiary)),
      );
    }
    if (block is Paragraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(block.text,
            style: AppText.bodyMd().copyWith(height: 1.6, color: AppColors.onBackground)),
      );
    }
    if (block is Highlight) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        child: Text(block.text,
            style: AppText.bodyMd().copyWith(
                height: 1.5, color: AppColors.primary, fontWeight: FontWeight.w600)),
      );
    }
    if (block is EducatorNote) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.school, color: AppColors.tertiary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(block.text,
                  style: AppText.bodyMd().copyWith(
                      height: 1.6, color: AppColors.tertiary, fontFamily: 'serif')),
            ),
          ],
        ),
      );
    }
    if (block is Cta) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.tertiary.withValues(alpha: 0.1),
          ]),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(block.text,
            style: AppText.bodyLg().copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
      );
    }
    if (block is DividerBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('✦', style: AppText.labelCaps().copyWith(color: AppColors.outlineVariant)),
            ),
            const Expanded(child: Divider(color: AppColors.outlineVariant)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _bottomCta(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: HeroButton(
          label: 'LANJUT KE QUIZ',
          trailingIcon: Icons.quiz,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BelajarQuizScreen(moduleId: widget.moduleId),
            )).then((_) {
              if (mounted) Navigator.pop(context); // return to hub after quiz
            });
          },
        ),
      ),
    );
  }
}
