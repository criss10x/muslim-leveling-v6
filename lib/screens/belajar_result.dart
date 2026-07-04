import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import '../../services/game_service.dart';
import 'naik_level_screen.dart';
import 'dapet_exp_screen.dart';

/// Quiz result — score, XP claim, next module unlock, level-up check.
class BelajarResultScreen extends StatefulWidget {
  final String moduleId;
  final int score;
  final int correct;
  final int total;

  const BelajarResultScreen({
    super.key,
    required this.moduleId,
    required this.score,
    required this.correct,
    required this.total,
  });

  @override
  State<BelajarResultScreen> createState() => _BelajarResultScreenState();
}

class _BelajarResultScreenState extends State<BelajarResultScreen> {
  bool _xpClaimed = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    // XP modul ini mungkin sudah diklaim di attempt sebelumnya — tanpa ini
    // tombol klaim muncul lagi tiap retake dan addXp jalan berulang.
    _xpClaimed = LearningService.isXpClaimed(widget.moduleId);
  }

  LearningModule get _module => LearningContent.getAllModulesOrdered()
      .where((m) => m.id == widget.moduleId)
      .first;

  bool get _passed => widget.score >= 70;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _trophy(),
                const SizedBox(height: AppSpacing.lg),
                _scoreCard(),
                const SizedBox(height: AppSpacing.lg),
                if (_passed && !_xpClaimed) _claimButton(),
                if (_passed && _xpClaimed) _claimedBadge(),
                if (!_passed) _retryHint(),
                const SizedBox(height: AppSpacing.lg),
                _actions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trophy() {
    final passed = _passed;
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (passed ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.15),
        border: Border.all(
            color: (passed ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.4),
            width: 3),
        boxShadow: [
          BoxShadow(
            color: (passed ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.3),
            blurRadius: 32,
          ),
        ],
      ),
      child: Icon(
        passed ? Icons.emoji_events : Icons.refresh,
        size: 48,
        color: passed ? AppColors.primary : AppColors.tertiary,
      ),
    );
  }

  Widget _scoreCard() {
    final passed = _passed;
    final color = passed ? AppColors.primary : AppColors.tertiary;
    return GlassPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(passed ? 'SELAMAT!' : 'BELUM LULUS',
              style: AppText.headlineLg().copyWith(fontSize: 24, color: color)),
          const SizedBox(height: AppSpacing.sm),
          Text('${widget.correct}/${widget.total} Benar',
              style: AppText.titleLg().copyWith(color: AppColors.onBackground)),
          const SizedBox(height: AppSpacing.md),
          Text('${widget.score}%',
              style: AppText.displayHero(48).copyWith(
                  color: color,
                  shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 20)])),
          const SizedBox(height: AppSpacing.sm),
          Text(
            passed
                ? 'Kamu lulus quiz ${_module.title}!'
                : 'Minimal 70% untuk lulus. Coba lagi ya!',
            style: AppText.bodyMd().copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _claimButton() {
    return SizedBox(
      width: double.infinity,
      child: HeroButton(
        label: 'KLAIM +${_module.xpReward} XP',
        trailingIcon: Icons.stars,
        onPressed: _processing ? null : _claimXp,
      ),
    );
  }

  Future<void> _claimXp() async {
    if (_processing) return;
    setState(() => _processing = true);

    // Claim learning XP (mark as claimed in learning state)
    await LearningService.claimXp(widget.moduleId);

    // Add XP to game state + check level up
    final (_, didLevelUp) = await GameService.addXp(_module.xpReward);

    setState(() {
      _xpClaimed = true;
      _processing = false;
    });

    if (!mounted) return;
    if (didLevelUp) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NaikLevelScreen(xpGained: _module.xpReward),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DapetExpScreen(
          xpGained: _module.xpReward,
          moduleTitle: _module.title,
          score: widget.score,
        ),
      ));
    }
  }

  Widget _claimedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('+${_module.xpReward} XP diklaim!',
              style: AppText.titleLg().copyWith(color: AppColors.primary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _retryHint() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        '💡 Tip: Baca lagi artikelnya, lalu coba quiz lagi. Kamu pasti bisa!',
        style: AppText.bodyMd().copyWith(color: AppColors.tertiary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Back to learning hub
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurfaceVariant,
              side: BorderSide(color: AppColors.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl)),
            ),
            child: Text('KE BELAJAR', style: AppText.labelCaps()),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (!_passed)
          Expanded(
            child: HeroButton(
              label: 'COBA LAGI',
              trailingIcon: Icons.refresh,
              onPressed: () {
                Navigator.of(context).pop(); // pop result
                Navigator.of(context).pop(); // pop quiz
              },
            ),
          ),
      ],
    );
  }
}
