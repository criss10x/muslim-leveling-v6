import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'belajar_result.dart';

/// Belajar Quiz — 5 questions, segmented progress, ABCD options with glow on select.
class BelajarQuizScreen extends StatefulWidget {
  const BelajarQuizScreen({super.key});

  @override
  State<BelajarQuizScreen> createState() => _BelajarQuizScreenState();
}

class _BelajarQuizScreenState extends State<BelajarQuizScreen> {
  int _q = 0;
  int? _picked;
  final _questions = const [
    (
      'Apa arti dari sifat Wajib bagi Allah?',
      [
        'Sifat yang mungkin ada dan mungkin tidak ada',
        'Sifat yang pasti dan harus ada pada Allah',
        'Sifat yang mustahil dimiliki oleh Allah',
        'Sifat yang bisa berubah-ubah',
      ],
      1,
    ),
    (
      'Berapa jumlah sifat wajib bagi Allah?',
      [
        '10 sifat',
        '15 sifat',
        '20 sifat',
        '25 sifat',
      ],
      2,
    ),
    (
      'Sifat "Wujud" bagi Allah bermakna...',
      [
        'Allah Maha Besar',
        'Allah Maha Ada',
        'Allah Maha Kaya',
        'Allah Maha Mulia',
      ],
      1,
    ),
    (
      'Lawan dari sifat wajib adalah...',
      [
        'Sifat jaiz',
        'Sifat mustahil',
        'Sifat af\'al',
        'Sifat dzatiyah',
      ],
      1,
    ),
    (
      '"Qidam" artinya...',
      [
        'Berdiri sendiri',
        'Terdahulu / tidak berpermulaan',
        'Kekal / tidak berakhir',
        'Maha Esa',
      ],
      1,
    ),
  ];

  void _next() {
    if (_q < _questions.length - 1) {
      setState(() {
        _q++;
        _picked = null;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BelajarResultScreen(
            correct: _picked == _questions[_q].$3 ? 5 : 4,
            total: 5,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_q];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Quiz: Mengenal Allah', style: AppText.titleLg().copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERTANYAAN ${_q + 1} DARI 5',
                style: AppText.labelCaps().copyWith(color: AppColors.tertiaryFixed),
              ),
              Text(
                'XP +50',
                style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          NeonProgressBar(
            progress: (_q + 1) / _questions.length,
            segmented: true,
            segments: 5,
            height: 12,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_center,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  q.$1,
                  style: AppText.headlineMd().copyWith(fontSize: 22, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(q.$2.length, (i) {
            final selected = _picked == i;
            final letter = String.fromCharCode(65 + i);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => setState(() => _picked = i),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.surfaceContainer
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: AppText.labelCaps().copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            q.$2[i],
                            style: AppText.bodyLg().copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),
          HeroButton(
            label: _q == _questions.length - 1 ? 'KIRIM JAWABAN' : 'LANJUT',
            trailingIcon: Icons.arrow_forward,
            onPressed: _picked == null ? null : _next,
          ),
        ],
      ),
    );
  }
}
