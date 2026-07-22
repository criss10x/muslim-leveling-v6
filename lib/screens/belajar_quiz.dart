import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import 'belajar_result.dart';

/// Quiz screen — 5 questions per module, ABCD options, instant feedback.
class BelajarQuizScreen extends StatefulWidget {
  final String moduleId;
  const BelajarQuizScreen({super.key, required this.moduleId});
  @override
  State<BelajarQuizScreen> createState() => _BelajarQuizScreenState();
}

class _BelajarQuizScreenState extends State<BelajarQuizScreen> {
  LearningModule? _module;
  late final List<QuizQuestion> _questions;
  int _current = 0;
  int? _selected;
  bool _answered = false;
  final List<bool> _correct = [];

  @override
  void initState() {
    super.initState();
    _module = LearningContent.getModule(widget.moduleId);
    _questions = LearningContent.getQuiz(widget.moduleId);
  }

  void _answer(int idx) {
    if (_answered || _questions.isEmpty) return;
    setState(() {
      _selected = idx;
      _answered = true;
      _correct.add(idx == _questions[_current].correctIndex);
    });
  }

  void _next() {
    if (_questions.isEmpty) return;
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    // ponytail: empty quiz → 0% (not NaN/Infinity)
    final score = _questions.isEmpty
        ? 0
        : (_correct.where((c) => c).length / _questions.length * 100).round();
    await LearningService.completeModule(widget.moduleId, score);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => BelajarResultScreen(
        moduleId: widget.moduleId,
        score: score,
        correct: _correct.where((c) => c).length,
        total: _questions.length,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    if (module == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Modul tidak ditemukan', style: AppText.titleLg()),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quiz belum tersedia', style: AppText.titleLg()),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final q = _questions[_current];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _header(module),
            _progress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PERTANYAAN ${_current + 1}/${_questions.length}',
                        style: AppText.labelCaps().copyWith(color: AppColors.tertiary)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(q.question,
                        style: AppText.headlineMd().copyWith(fontSize: 20, height: 1.4)),
                    const SizedBox(height: AppSpacing.lg),
                    ...List.generate(q.options.length, (i) => _optionCard(q, i)),
                    if (_answered) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _explanationCard(q),
                    ],
                  ],
                ),
              ),
            ),
            if (_answered) _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header(LearningModule module) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(module.title,
                style: AppText.titleLg().copyWith(fontSize: 15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: List.generate(_questions.length, (i) {
          final done = i < _current || (i == _current && _answered);
          final correct = i < _correct.length ? _correct[i] : false;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              height: 4,
              decoration: BoxDecoration(
                color: done
                    ? (correct ? AppColors.primary : AppColors.error)
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _optionCard(QuizQuestion q, int i) {
    final isCorrect = i == q.correctIndex;
    final isSelected = i == _selected;
    final showCorrect = _answered && isCorrect;
    final showWrong = _answered && isSelected && !isCorrect;

    Color borderColor = AppColors.outlineVariant.withValues(alpha: 0.3);
    Color bgColor = AppColors.surfaceContainer.withValues(alpha: 0.6);
    Color textColor = AppColors.onBackground;
    IconData? icon;

    if (showCorrect) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.15);
      textColor = AppColors.primary;
      icon = Icons.check_circle;
    } else if (showWrong) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.1);
      textColor = AppColors.error;
      icon = Icons.cancel;
    } else if (_answered) {
      borderColor = AppColors.outlineVariant.withValues(alpha: 0.2);
      textColor = AppColors.onSurfaceVariant;
    }

    final letters = ['A', 'B', 'C', 'D', 'E'];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: _answered ? null : () => _answer(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: showCorrect || showWrong ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showCorrect
                      ? AppColors.primary
                      : (showWrong ? AppColors.error : AppColors.surfaceContainerHigh),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: Colors.white, size: 16)
                      : Text(letters[i],
                          style: AppText.labelCaps().copyWith(color: textColor, fontSize: 12)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(q.options[i],
                    style: AppText.bodyMd().copyWith(color: textColor, height: 1.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explanationCard(QuizQuestion q) {
    final wasCorrect = _selected == q.correctIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (wasCorrect ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: (wasCorrect ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(wasCorrect ? Icons.check_circle : Icons.lightbulb,
                  color: wasCorrect ? AppColors.primary : AppColors.tertiary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(wasCorrect ? 'BENAR!' : 'Belum tepat',
                  style: AppText.titleLg().copyWith(
                      fontSize: 14, color: wasCorrect ? AppColors.primary : AppColors.tertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(q.explanation,
              style: AppText.bodyMd().copyWith(height: 1.5, color: AppColors.onBackground)),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: HeroButton(
          label: _current < _questions.length - 1
              ? 'PERTANYAAN BERIKUTNYA'
              : 'LIHAT HASIL',
          trailingIcon: Icons.arrow_forward,
          onPressed: _next,
        ),
      ),
    );
  }
}
