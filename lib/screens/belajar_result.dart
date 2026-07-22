import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/learning_content.dart';
import '../../services/game_service.dart';
import 'naik_level_screen.dart';
import 'dapet_exp_screen.dart';

/// Quiz result — redesigned per spec: victory badge, glass score card,
/// gradient heading, float animation, hero + ghost action buttons.
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

  LearningModule? get _module => LearningContent.getModule(widget.moduleId);

  bool get _passed => widget.score >= LearningService.passScore;

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
    final bgColor = _passed ? AppColors.primary : AppColors.tertiary;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              bgColor.withValues(alpha: 0.18),
              AppColors.background,
              AppColors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Bottom glow
            Positioned(
              bottom: -40, left: 0, right: 0,
              child: IgnorePointer(
                child: Container(height: 160,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter, radius: 1.2,
                      colors: [
                        AppColors.secondaryFixed.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
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
                      if (_passed && !_xpClaimed) _claimButton(module),
                      if (_passed && _xpClaimed) _claimedBadge(module),
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
      ),
    );
  }

  Widget _victoryBadge() {
    final light = isLightTheme;
    final accent = _passed ? AppColors.secondaryFixed : AppColors.tertiary;
    final iconColor =
        _passed ? AppColors.onSecondaryFixed : AppColors.onTertiaryContainer;
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) {
        final floatY = math.sin(_floatCtrl.value * math.pi) * 8;
        return Transform.translate(offset: Offset(0, -floatY), child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: light ? 0.12 : 0.2),
              boxShadow: light
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
            ),
          ),
          ClipPath(
            clipper: const _DiamondClipper(),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // Light fail: soft container (Fixed = fill-only, muddy as surface).
                  colors: _passed
                      ? [AppColors.secondaryFixed, AppColors.onSecondaryFixed]
                      : light
                          ? [
                              AppColors.tertiaryContainer,
                              AppColors.tertiary.withValues(alpha: 0.35),
                            ]
                          : [
                              AppColors.tertiaryFixed,
                              AppColors.tertiaryContainer,
                            ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.7), width: 2),
                boxShadow: light
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
              ),
              child: Icon(
                _passed ? Icons.workspace_premium : Icons.refresh,
                size: 52,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading() {
    final light = isLightTheme;
    final title = _passed ? 'Modul Selesai!' : 'Belum Lulus';
    if (light) {
      return Text(
        title,
        textAlign: TextAlign.center,
        style: AppText.displayHero(40).copyWith(
          color: AppColors.onSurface,
          fontSize: 32,
        ),
      );
    }
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        colors: [AppColors.primary, AppColors.tertiary],
      ).createShader(rect),
      child: Text(
        title,
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
      _passed ? 'Pengetahuanmu semakin bertambah.' : 'Minimal 70% untuk lulus. Coba lagi ya!',
      textAlign: TextAlign.center,
      style: AppText.bodyLg().copyWith(color: AppColors.onSurfaceVariant),
    );
  }

  Widget _scoreCard() {
    final light = isLightTheme;
    final accent = _passed ? AppColors.secondaryFixed : AppColors.tertiary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: light
            ? AppColors.surfaceContainerLow
            : AppColors.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.xxl + 8),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: light ? 0.7 : 0.4),
        ),
        boxShadow: light
            ? null
            : const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                accent.withValues(alpha: 0.6),
                Colors.transparent,
              ]),
            ),
          ),
          Text(
            'HASIL QUIZ',
            style: AppText.labelCaps().copyWith(color: accent, letterSpacing: 3),
          ),
          const SizedBox(height: 12),
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
                  shadows: light
                      ? null
                      : [
                          Shadow(
                            color: accent.withValues(alpha: 0.6),
                            blurRadius: 25,
                          ),
                        ],
                ),
              ),
              Text('%', style: AppText.headlineMd().copyWith(color: accent)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('${widget.correct}/${widget.total} Benar',
                    style: AppText.titleLg().copyWith(color: AppColors.primary, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _claimButton(LearningModule module) {
    return SizedBox(
      width: double.infinity,
      child: HeroButton(
        label: 'KLAIM +${module.xpReward} XP',
        trailingIcon: Icons.stars,
        onPressed: _processing ? null : () => _claimXp(module),
      ),
    );
  }

  Future<void> _claimXp(LearningModule module) async {
    if (_processing) return;
    setState(() => _processing = true);
    await LearningService.claimXp(widget.moduleId);
    final (_, levelsGained) = await GameService.addXp(module.xpReward);
    setState(() { _xpClaimed = true; _processing = false; });
    if (!mounted) return;
    if (levelsGained > 0) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NaikLevelScreen(xpGained: module.xpReward, levelsGained: levelsGained),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DapetExpScreen(xpGained: module.xpReward, moduleTitle: module.title, score: widget.score),
      ));
    }
  }

  Widget _claimedBadge(LearningModule module) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Text('+${module.xpReward} XP',
              style: AppText.headlineMd().copyWith(color: AppColors.primary, fontSize: 22)),
          const SizedBox(width: 8),
          Text('Diperoleh', style: AppText.labelCaps().copyWith(color: AppColors.onSurfaceVariant)),
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
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: AppColors.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Baca lagi artikelnya, lalu coba quiz lagi. Kamu pasti bisa!',
                style: AppText.bodyMd().copyWith(color: AppColors.tertiary)),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: HeroButton(
            label: 'Kembali ke Hub',
            trailingIcon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ),
        const SizedBox(height: 8),
        if (!_passed)
          SizedBox(
            width: double.infinity,
            child: GhostButton(
              label: 'COBA LAGI', icon: Icons.replay,
              onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
              color: AppColors.tertiary,
            ),
          ),
        if (_passed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: BorderSide(color: AppColors.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('BALIK KE ARTIKEL', style: AppText.labelCaps()),
            ),
          ),
      ],
    );
  }
}

/// Diamond clipper — sharp edges, no anti-alias blur.
class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width / 2, 0)
    ..lineTo(size.width, size.height / 2)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height / 2)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
