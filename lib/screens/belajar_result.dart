import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import '../../services/game_service.dart';
import 'naik_level_screen.dart';
import 'dapet_exp_screen.dart';

/// Quiz result — redesigned per spec: victory badge, glass score card,
/// gradient heading, shine/float animations, hero + ghost action buttons.
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

class _BelajarResultScreenState extends State<BelajarResultScreen>
    with SingleTickerProviderStateMixin {
  bool _xpClaimed = false;
  bool _processing = false;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _xpClaimed = LearningService.isXpClaimed(widget.moduleId);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  LearningModule get _module => LearningContent.getAllModulesOrdered()
      .where((m) => m.id == widget.moduleId)
      .first;

  bool get _passed => widget.score >= LearningService.passScore;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background glow layers ──
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      (_passed ? AppColors.primary : AppColors.tertiary)
                          .withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: 1.2,
                    colors: [
                      AppColors.secondaryFixed.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    _victoryBadge(),
                    const SizedBox(height: 20),
                    _heading(),
                    const SizedBox(height: 8),
                    _subheading(),
                    const SizedBox(height: 24),
                    _scoreCard(),
                    const SizedBox(height: 20),
                    if (_passed && !_xpClaimed) _claimButton(),
                    if (_passed && _xpClaimed) _claimedBadge(),
                    if (!_passed) _retryHint(),
                    const SizedBox(height: 24),
                    _actions(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating victory badge ──
  Widget _victoryBadge() {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) {
        final floatY = math.sin(_floatCtrl.value * math.pi) * 8;
        return Transform.translate(offset: Offset(0, -floatY), child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_passed
                      ? AppColors.secondaryFixed
                      : AppColors.tertiary)
                  .withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: (_passed
                          ? AppColors.secondaryFixed
                          : AppColors.tertiary)
                      .withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Rotated diamond
          Transform.rotate(
            angle: 0.785, // 45 deg
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _passed
                      ? [AppColors.secondaryFixed, AppColors.onSecondaryFixed]
                      : [AppColors.tertiaryFixed, AppColors.tertiaryContainer],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (_passed ? AppColors.secondaryFixed : AppColors.tertiary)
                      .withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_passed
                            ? AppColors.secondaryFixed
                            : AppColors.tertiary)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: -0.785, // counter-rotate the icon
                child: Icon(
                  _passed ? Icons.workspace_premium : Icons.refresh,
                  size: 52,
                  color: _passed
                      ? AppColors.onSecondaryFixed
                      : AppColors.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient heading ──
  Widget _heading() {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [AppColors.primary, AppColors.tertiary],
      ).createShader(rect),
      child: Text(
        _passed ? 'Modul Selesai!' : 'Belum Lulus',
        textAlign: TextAlign.center,
        style: AppText.displayHero(40).copyWith(
          color: Colors.white,
          fontSize: 32,
          shadows: [
            Shadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _subheading() {
    return Text(
      _passed
          ? 'Pengetahuanmu semakin bertambah.'
          : 'Minimal 70% untuk lulus. Coba lagi ya!',
      textAlign: TextAlign.center,
      style: AppText.bodyLg().copyWith(color: AppColors.onSurfaceVariant),
    );
  }

  // ── Glass score card ──
  Widget _scoreCard() {
    final accent = _passed ? AppColors.secondaryFixed : AppColors.tertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Column(
          children: [
            // Top accent glow border
            Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Label
            Text(
              'HASIL QUIZ',
              style: AppText.labelCaps().copyWith(
                color: accent,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            // Large score
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.score}',
                  style: AppText.displayHero(48).copyWith(
                    color: accent,
                    fontSize: 56,
                    shadows: [
                      Shadow(
                        color: accent.withValues(alpha: 0.6),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                ),
                Text(
                  '%',
                  style: AppText.headlineMd().copyWith(
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Accuracy pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.correct}/${widget.total} Benar',
                    style: AppText.titleLg().copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── XP reward chip ──
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

    await LearningService.claimXp(widget.moduleId);
    final (_, levelsGained) = await GameService.addXp(_module.xpReward);

    setState(() {
      _xpClaimed = true;
      _processing = false;
    });

    if (!mounted) return;
    if (levelsGained > 0) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NaikLevelScreen(
            xpGained: _module.xpReward, levelsGained: levelsGained),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            '+${_module.xpReward} XP',
            style: AppText.headlineMd().copyWith(
              color: AppColors.primary,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Diperoleh',
            style: AppText.labelCaps().copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _retryHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: AppColors.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Baca lagi artikelnya, lalu coba quiz lagi. Kamu pasti bisa!',
              style: AppText.bodyMd().copyWith(color: AppColors.tertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        // Primary — Kembali ke Hub
        SizedBox(
          width: double.infinity,
          child: HeroButton(
            label: 'Kembali ke Hub',
            trailingIcon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.isFirst),
          ),
        ),
        const SizedBox(height: 8),
        // Ghost — Coba Lagi (only if failed)
        if (!_passed)
          SizedBox(
            width: double.infinity,
            child: GhostButton(
              label: 'COBA LAGI',
              icon: Icons.replay,
              onPressed: () {
                Navigator.of(context).pop(); // pop result
                Navigator.of(context).pop(); // pop quiz
              },
              color: AppColors.tertiary,
            ),
          ),
        if (_passed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(); // pop result
                Navigator.of(context).pop(); // pop quiz
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: BorderSide(color: AppColors.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('BALIK KE ARTIKEL', style: AppText.labelCaps()),
            ),
          ),
      ],
    );
  }
}
