import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../services/achievement_service.dart';
import '../services/game_service.dart';
import 'achievement_medal.dart';

// ═══════════════════════════════════════════════════════════════
// SHARE CARD — Kartu 9:16 buat di-share ke IG Story, WA, dll.
// Render via RepaintBoundary, capture → PNG → share.
// ═══════════════════════════════════════════════════════════════

/// Warna background + glow per tier untuk kartu.
(Color bg1, Color bg2, Color glow, Color accent) _tierStyle(
    AchievementTier tier, String id) {
  // Collector / Hall of Fame → gradient emas-merah premium
  if (id == 'collector' || id == 'hall_of_fame') {
    return (const Color(0xFF1A0A0A), const Color(0xFF2D1810),
        const Color(0xFFFFD700), const Color(0xFFDC2626));
  }
  return switch (tier) {
    AchievementTier.rookie => (const Color(0xFF0E1512), const Color(0xFF1A211E),
        const Color(0xFF6B7280), const Color(0xFF00A86B)),
    AchievementTier.elite => (const Color(0xFF0E1512), const Color(0xFF0A2E22),
        const Color(0xFF10B981), const Color(0xFF059669)),
    AchievementTier.gold => (const Color(0xFF0E1512), const Color(0xFF1E1600),
        const Color(0xFFFFD700), const Color(0xFFF59E0B)),
    AchievementTier.epic => (const Color(0xFF0E1512), const Color(0xFF0D0828),
        const Color(0xFF6366F1), const Color(0xFF8B5CF6)),
    AchievementTier.legendary => (const Color(0xFF0E1512), const Color(0xFF1A0E00),
        const Color(0xFFFFD700), const Color(0xFFDC2626)),
  };
}

// ── Star particle painter (legendary/epic preview animation) ──

class _StarParticlePainter extends CustomPainter {
  final double phase;
  final Color color;

  _StarParticlePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.6);
    final rng = Random(42);
    for (var i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + phase * 60) % size.height;
      final s = 1.5 + rng.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarParticlePainter old) =>
      old.phase != phase;
}

// ── Islamic geometric divider ──

class _GeoDivider extends StatelessWidget {
  final Color color;
  const _GeoDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        8,
        (i) => Padding(
          padding: EdgeInsets.symmetric(horizontal: i == 0 ? 0 : 4),
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3 + 0.1 * (i % 3)),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── The card widget (inside RepaintBoundary) ──

class _ShareCardRender extends StatelessWidget {
  final AchievementDef def;
  final String username;
  final int heroStreak;
  final int level;
  final String rankTitle;

  const _ShareCardRender({
    required this.def,
    required this.username,
    required this.heroStreak,
    required this.level,
    required this.rankTitle,
  });

  @override
  Widget build(BuildContext context) {
    final (bg1, bg2, glow, accent) = _tierStyle(def.tier, def.id);
    const cardWidth = 320.0;
    const cardHeight = cardWidth * 16 / 9;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg1, bg2],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Layer: glow burst di badge
          Positioned(
            top: cardHeight * 0.20,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.35),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                // ── HEADER ──
                Text(
                  'MUSLIM LEVELING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level Up Iman, Level Up Kehidupanmu',
                  style: TextStyle(
                    fontSize: 8,
                    color: accent.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(flex: 1),

                // ── BADGE ICON ──
                AchievementMedal(def: def, unlocked: true, size: 100),
                const SizedBox(height: 8),

                // ── TIER LABEL ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.4), width: 0.5),
                  ),
                  child: Text(
                    tierLabel(def.tier),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: accent,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── BADGE NAME ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: bg2.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: glow.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Text(
                    def.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: glow,
                      shadows: [
                        Shadow(
                          color: glow.withValues(alpha: 0.6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── USER INFO ──
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hero Streak: $heroStreak 🔥',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rank: $rankTitle',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.secondaryFixed,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                // ── FOOTER ──
                _GeoDivider(color: accent),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, size: 10,
                        color: accent.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Download Muslim Leveling',
                      style: TextStyle(
                        fontSize: 8,
                        color: accent.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PUBLIC API: Show preview dialog → capture → share
// ═══════════════════════════════════════════════════════════════

/// Tampilkan preview kartu achievement, lalu share/generate gambar.
Future<void> showShareCard(BuildContext context, AchievementDef def) async {
  final state = GameService.current;
  final rankTitle = GameService.getRankTitle(state.level);
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString('nickname') ?? 'Pejuang';
  final heroStreak = max(state.heroStreak.current, state.heroStreak.best);
  final level = state.level;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) => _SharePreviewDialog(
      def: def,
      username: username,
      heroStreak: heroStreak,
      level: level,
      rankTitle: rankTitle,
    ),
  );
}

class _SharePreviewDialog extends StatefulWidget {
  final AchievementDef def;
  final String username;
  final int heroStreak;
  final int level;
  final String rankTitle;

  const _SharePreviewDialog({
    required this.def,
    required this.username,
    required this.heroStreak,
    required this.level,
    required this.rankTitle,
  });

  @override
  State<_SharePreviewDialog> createState() => _SharePreviewDialogState();
}

class _SharePreviewDialogState extends State<_SharePreviewDialog>
    with SingleTickerProviderStateMixin {
  final _repaintKey = GlobalKey();
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _starCtrl;
  bool _sharing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _animCtrl.forward();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.def.tier == AchievementTier.epic ||
        widget.def.tier == AchievementTier.legendary ||
        widget.def.id == 'collector' ||
        widget.def.id == 'hall_of_fame') {
      _starCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureAndShare() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) setState(() => _sharing = false);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        if (mounted) setState(() => _sharing = false);
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/muslim_leveling_${widget.def.id}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      if (!mounted) return;
      setState(() => _saved = true);

      const channel = MethodChannel('muslim_leveling/share');
      await channel.invokeMethod('shareFile', {
        'filePath': file.path,
        'text': 'Aku unlock "${widget.def.title}" di Muslim Leveling! 🎮🕌',
      });
    } catch (_) {
      // silent
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final (_, _, glow, accent) =
        _tierStyle(widget.def.tier, widget.def.id);
    final hasStars = _starCtrl.isAnimating;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Card preview ──
          FadeTransition(
            opacity: _scaleAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: RepaintBoundary(
                key: _repaintKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      _ShareCardRender(
                        def: widget.def,
                        username: widget.username,
                        heroStreak: widget.heroStreak,
                        level: widget.level,
                        rankTitle: widget.rankTitle,
                      ),
                      // Star particles overlay (legendary/epic)
                      if (hasStars)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _starCtrl,
                              builder: (_, child) => CustomPaint(
                                painter: _StarParticlePainter(
                                  phase: _starCtrl.value,
                                  color: glow,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Action buttons ──
          Row(
            children: [
              // Bagikan
              Expanded(
                child: _actionBtn(
                  icon: Icons.share,
                  label: _saved ? 'Bagikan Lagi' : 'Bagikan ke Story',
                  color: AppColors.primary,
                  loading: _sharing,
                  onTap: _captureAndShare,
                ),
              ),
              const SizedBox(width: 12),
              // Tutup
              _actionBtn(
                icon: Icons.check,
                label: 'Tutup',
                color: AppColors.onSurfaceVariant,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: loading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
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
