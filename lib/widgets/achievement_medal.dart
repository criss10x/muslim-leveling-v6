import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/achievement_service.dart';
import 'common.dart';
import 'share_card.dart';

/// Medali achievement ala Mobile Legends — heksagon dengan gradient tier,
/// glow, dan glyph di tengah (ikon untuk momen pertama, angka hari untuk
/// medali streak). Digambar penuh lewat CustomPainter: vector, ikut tema,
/// tanpa file asset.

/// Warna gradient per tier — selaras palet app (emerald/cyan/gold) +
/// crimson→gold untuk tier atas, senada dengan tier avatar profil.
(Color, Color) tierColors(AchievementTier tier) => switch (tier) {
      AchievementTier.rookie => (AppColors.primary, const Color(0xFF14B8A6)),
      AchievementTier.elite =>
        (AppColors.tertiary, AppColors.tertiaryFixed),
      AchievementTier.gold =>
        (AppColors.secondaryFixed, AppColors.secondaryFixedDim),
      AchievementTier.epic =>
        (const Color(0xFFDC2626), const Color(0xFFEC4899)),
      AchievementTier.legendary =>
        (const Color(0xFFF59E0B), const Color(0xFFDC2626)),
    };

String tierLabel(AchievementTier tier) => switch (tier) {
      AchievementTier.rookie => 'ROOKIE',
      AchievementTier.elite => 'ELITE',
      AchievementTier.gold => 'GOLD',
      AchievementTier.epic => 'EPIC',
      AchievementTier.legendary => 'LEGENDARY',
    };

class AchievementMedal extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  final double size;

  const AchievementMedal({
    super.key,
    required this.def,
    required this.unlocked,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final (c1, c2) = tierColors(def.tier);
    final glyphColor = unlocked ? Colors.white : AppColors.onSurfaceVariant;

    Widget glyph;
    if (!unlocked) {
      glyph = Icon(Icons.lock, size: size * 0.30, color: glyphColor);
    } else if (def.glyphText != null) {
      // Kill-count ala ML: angka hari besar + api kecil di atasnya.
      glyph = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: size * 0.18, color: c1),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              def.glyphText!,
              style: AppText.displayHero(size * 0.30).copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(color: c1.withValues(alpha: 0.8), blurRadius: 10),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      glyph = Icon(def.icon, size: size * 0.38, color: glyphColor, shadows: [
        Shadow(color: c1.withValues(alpha: 0.8), blurRadius: 12),
      ]);
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(
          primary: unlocked ? c1 : AppColors.onSurfaceVariant,
          secondary: unlocked ? c2 : AppColors.outlineVariant,
          unlocked: unlocked,
          legendary: unlocked && def.tier == AchievementTier.legendary,
        ),
        child: Center(
          child: SizedBox(width: size * 0.55, height: size * 0.55,
              child: Center(child: glyph)),
        ),
      ),
    );
  }
}

/// Heksagon pointy-top: glow blur di belakang, isi kaca gelap dengan tint
/// radial, border gradient, garis aksen heksagon dalam. Tier legendary
/// dapat bintang kecil di kedua sisi.
class _MedalPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final bool unlocked;
  final bool legendary;

  _MedalPainter({
    required this.primary,
    required this.secondary,
    required this.unlocked,
    required this.legendary,
  });

  Path _hexagon(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (60 * i - 90) * pi / 180; // pointy-top
      final p = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final hex = _hexagon(center, r);
    final rect = Offset.zero & size;

    // Glow lembut di belakang medali (hanya saat terbuka).
    if (unlocked) {
      canvas.drawPath(
        _hexagon(center, r * 0.98),
        Paint()
          ..color = primary.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // Isi: kaca gelap + tint radial warna tier dari atas.
    canvas.drawPath(
      hex,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: [
            primary.withValues(alpha: unlocked ? 0.30 : 0.10),
            const Color(0xFF0E1512),
          ],
        ).createShader(rect),
    );

    // Border gradient mengikuti keliling heksagon.
    canvas.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unlocked ? 2.5 : 1.5
        ..strokeJoin = StrokeJoin.round
        ..shader = SweepGradient(
          colors: [primary, secondary, primary, secondary, primary],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(rect),
    );

    // Aksen heksagon dalam, tipis.
    canvas.drawPath(
      _hexagon(center, r * 0.78),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = (unlocked ? secondary : AppColors.onSurfaceVariant)
            .withValues(alpha: 0.35),
    );

    // Bintang kecil kiri-kanan untuk legendary.
    if (legendary) {
      final starPaint = Paint()..color = secondary;
      for (final dx in [-r * 0.92, r * 0.92]) {
        _drawStar(canvas, center + Offset(dx, 0), r * 0.10, starPaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (45 * i - 90) * pi / 180;
      final len = i.isEven ? radius : radius * 0.4;
      final p = Offset(c.dx + len * cos(angle), c.dy + len * sin(angle));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.primary != primary ||
      old.secondary != secondary ||
      old.unlocked != unlocked;
}

/// Popup announcer ala Mobile Legends: backdrop blur gelap, medali masuk
/// dengan pantulan elastis, judul menyala, confetti. Tap di mana saja atau
/// tombol untuk menutup. Await sampai ditutup — antre kalau unlock banyak.
Future<void> showAchievementUnlock(
    BuildContext context, AchievementDef def) async {
  final (c1, _) = tierColors(def.tier);
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'achievement',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, __) => Center(
      child: Material(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: GlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  borderColor: c1.withValues(alpha: 0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ACHIEVEMENT UNLOCKED!',
                        style: AppText.labelCaps().copyWith(
                          color: AppColors.secondaryFixed,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: ShimmerSweep(
                          child: AchievementMedal(
                              def: def, unlocked: true, size: 130),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        def.title,
                        textAlign: TextAlign.center,
                        style: AppText.displayHero(30).copyWith(
                          color: c1,
                          shadows: [
                            Shadow(
                                color: c1.withValues(alpha: 0.7),
                                blurRadius: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        def.desc,
                        textAlign: TextAlign.center,
                        style: AppText.bodyMd()
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tierLabel(def.tier),
                        style: AppText.labelCaps()
                            .copyWith(color: c1, fontSize: 10),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: HeroButton(
                              label: 'MANTAP!',
                              trailingIcon: Icons.emoji_events,
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: () => showShareCard(context, def),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c1,
                              side: BorderSide(color: c1.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share, size: 16, color: c1),
                                const SizedBox(width: 6),
                                Text(
                                  'Bagikan',
                                  style: AppText.bodyLg().copyWith(color: c1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiBurst(particleCount: 45),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Dialog detail saat medali di-tap dari grid profil.
void showAchievementDetail(
  BuildContext context,
  AchievementDef def, {
  required bool unlocked,
  String? unlockedDate,
}) {
  final (c1, _) = tierColors(def.tier);
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: c1.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AchievementMedal(def: def, unlocked: unlocked, size: 96),
            const SizedBox(height: AppSpacing.md),
            Text(
              def.title,
              textAlign: TextAlign.center,
              style: AppText.headlineMd().copyWith(
                color: unlocked ? c1 : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              def.desc,
              textAlign: TextAlign.center,
              style: AppText.bodyMd()
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              unlocked
                  ? 'Terbuka ${unlockedDate ?? ''} • ${tierLabel(def.tier)}'
                  : 'Terkunci • ${tierLabel(def.tier)}',
              style: AppText.labelCaps().copyWith(
                color: unlocked ? c1 : AppColors.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
