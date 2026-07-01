import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// TIER PROFILE AVATAR — Square rounded 16dp with progressive tier borders
//
// Tier progression (makin tinggi makin epik):
//   Warrior        — Solid 2dp purple
//   Elite          — Solid 3dp blue + corner accents
//   Master         — Gradient teal→emerald 3dp
//   Grandmaster    — Gradient gold→amber 4dp + soft glow
//   Epic           — Gradient crimson 4dp + animated glow pulse
//   Legend         — Gradient white→gold 4dp + rotating shimmer ring
//   Mythic         — Gradient crimson→gold 5dp + rotating ring + particles
//   Mythic Honor   — + double rotating ring (opposite directions)
//   Mythic Glory   — + animated sparkles on border
//   Mythic Immortal — Full legendary: crown emblem + all effects active
// ═══════════════════════════════════════════════════════════════

class TierVisualConfig {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final double borderWidth;
  final bool hasCornerAccents;
  final bool hasGlow;
  final bool hasPulsingGlow;
  final bool hasRotatingRing;
  final bool hasParticles;
  final bool hasDoubleRing;
  final bool hasSparkles;
  final bool hasCrownEmblem;
  final String? cornerEmblem;

  const TierVisualConfig({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderWidth,
    this.hasCornerAccents = false,
    this.hasGlow = false,
    this.hasPulsingGlow = false,
    this.hasRotatingRing = false,
    this.hasParticles = false,
    this.hasDoubleRing = false,
    this.hasSparkles = false,
    this.hasCrownEmblem = false,
    this.cornerEmblem,
  });
}

TierVisualConfig getTierVisualConfig(String tierName) {
  switch (tierName) {
    case 'Warrior':
      return const TierVisualConfig(
        name: 'Warrior',
        primaryColor: Color(0xFF8B5CF6),
        secondaryColor: Color(0xFF6366F1),
        borderWidth: 2,
      );
    case 'Elite':
      return const TierVisualConfig(
        name: 'Elite',
        primaryColor: Color(0xFF3B82F6),
        secondaryColor: Color(0xFF06B6D4),
        borderWidth: 3,
        hasCornerAccents: true,
      );
    case 'Master':
      return const TierVisualConfig(
        name: 'Master',
        primaryColor: Color(0xFF14B8A6),
        secondaryColor: Color(0xFF10B981),
        borderWidth: 3,
      );
    case 'Grandmaster':
      return const TierVisualConfig(
        name: 'Grandmaster',
        primaryColor: Color(0xFFF59E0B),
        secondaryColor: Color(0xFFFCD34D),
        borderWidth: 4,
        hasGlow: true,
      );
    case 'Epic':
      return const TierVisualConfig(
        name: 'Epic',
        primaryColor: Color(0xFFDC2626),
        secondaryColor: Color(0xFFEC4899),
        borderWidth: 4,
        hasGlow: true,
        hasPulsingGlow: true,
      );
    case 'Legend':
      return const TierVisualConfig(
        name: 'Legend',
        primaryColor: Color(0xFFFFFFFF),
        secondaryColor: Color(0xFFF59E0B),
        borderWidth: 4,
        hasGlow: true,
        hasRotatingRing: true,
      );
    case 'Mythic':
      return const TierVisualConfig(
        name: 'Mythic',
        primaryColor: Color(0xFFDC2626),
        secondaryColor: Color(0xFFF59E0B),
        borderWidth: 5,
        hasGlow: true,
        hasRotatingRing: true,
        hasParticles: true,
      );
    case 'Mythic Honor':
      return const TierVisualConfig(
        name: 'Mythic Honor',
        primaryColor: Color(0xFFF59E0B),
        secondaryColor: Color(0xFFDC2626),
        borderWidth: 5,
        hasGlow: true,
        hasRotatingRing: true,
        hasParticles: true,
        hasDoubleRing: true,
      );
    case 'Mythic Glory':
      return const TierVisualConfig(
        name: 'Mythic Glory',
        primaryColor: Color(0xFFFFFFFF),
        secondaryColor: Color(0xFFDC2626),
        borderWidth: 5,
        hasGlow: true,
        hasRotatingRing: true,
        hasParticles: true,
        hasDoubleRing: true,
        hasSparkles: true,
      );
    case 'Mythic Immortal':
      return const TierVisualConfig(
        name: 'Mythic Immortal',
        primaryColor: Color(0xFFF59E0B),
        secondaryColor: Color(0xFFFFFFFF),
        borderWidth: 5,
        hasGlow: true,
        hasPulsingGlow: true,
        hasRotatingRing: true,
        hasParticles: true,
        hasDoubleRing: true,
        hasSparkles: true,
        hasCrownEmblem: true,
        cornerEmblem: '👑',
      );
    default:
      return const TierVisualConfig(
        name: 'Unknown',
        primaryColor: Color(0xFF6B7280),
        secondaryColor: Color(0xFF9CA3AF),
        borderWidth: 2,
      );
  }
}

/// Returns the tier name for a given level
String getTierName(int level) {
  if (level >= 95) return 'Mythic Immortal';
  if (level >= 90) return 'Mythic Glory';
  if (level >= 85) return 'Mythic Honor';
  if (level >= 80) return 'Mythic';
  if (level >= 60) return 'Legend';
  if (level >= 40) return 'Epic';
  if (level >= 30) return 'Grandmaster';
  if (level >= 20) return 'Master';
  if (level >= 10) return 'Elite';
  return 'Warrior';
}

/// Returns default emoji avatar for a tier when no photo is set
String _defaultEmoji(String tierName, TierVisualConfig config) {
  if (config.hasCrownEmblem) return '🤴';
  if (tierName.startsWith('Mythic')) return '🧙';
  if (tierName == 'Legend') return '🌟';
  if (tierName == 'Epic') return '🔥';
  if (tierName == 'Grandmaster') return '👑';
  if (tierName == 'Master') return '🎓';
  if (tierName == 'Elite') return '🛡️';
  return '🧕';
}

// ═══════════════════════════════════════════════════════════════
// TIER PROFILE AVATAR — Full animated version
// ═══════════════════════════════════════════════════════════════

class TierProfileAvatar extends StatefulWidget {
  final String? profileImagePath;
  final String tierName;
  final double sizeDp;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const TierProfileAvatar({
    super.key,
    this.profileImagePath,
    required this.tierName,
    this.sizeDp = 120,
    this.showEditBadge = false,
    this.onTap,
  });

  @override
  State<TierProfileAvatar> createState() => _TierProfileAvatarState();
}

class _TierProfileAvatarState extends State<TierProfileAvatar>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _ringReverseController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _ringReverseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _ringReverseController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = getTierVisualConfig(widget.tierName);
    final size = widget.sizeDp;
    final extraSize = size + 16; // space for effects
    final cornerRadius = 16.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: extraSize,
        height: extraSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layer 1: Outer glow (Grandmaster+)
            if (config.hasGlow)
              _buildGlowLayer(config, size, cornerRadius),

            // Layer 2: Rotating shimmer ring (Legend+)
            if (config.hasRotatingRing)
              _buildRotatingRing(config, size),

            // Layer 2b: Counter-rotating ring (Mythic Honor+)
            if (config.hasDoubleRing)
              _buildCounterRotatingRing(config, size),

            // Layer 3: Particles orbit (Mythic+)
            if (config.hasParticles)
              _buildParticleLayer(config, size),

            // Layer 4: Sparkles (Mythic Glory+)
            if (config.hasSparkles)
              _buildSparkleLayer(config, size),

            // Layer 5: Main avatar box with border
            _buildMainAvatar(config, size, cornerRadius),

            // Layer 6: Corner accents (Elite+)
            if (config.hasCornerAccents)
              _buildCornerAccents(config, size),

            // Layer 7: Crown emblem (Mythic Immortal)
            if (config.hasCrownEmblem)
              _buildCrownEmblem(size),

            // Layer 8: Edit badge
            if (widget.showEditBadge)
              _buildEditBadge(size),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowLayer(TierVisualConfig config, double size, double cornerRadius) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = config.hasPulsingGlow
            ? 0.3 + 0.4 * _pulseController.value
            : 0.4;
        return Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius + 6),
            boxShadow: [
              BoxShadow(
                color: config.primaryColor.withValues(alpha: glowAlpha),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRotatingRing(TierVisualConfig config, double size) {
    return AnimatedBuilder(
      animation: _ringController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _ringController.value * 2 * pi,
          child: CustomPaint(
            size: Size(size + 8, size + 8),
            painter: _ArcRingPainter(
              primaryColor: config.primaryColor,
              secondaryColor: config.secondaryColor,
              strokeWidth: 2,
              startAngle: 0,
              sweepAngle: 300,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCounterRotatingRing(TierVisualConfig config, double size) {
    return AnimatedBuilder(
      animation: _ringReverseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: -_ringReverseController.value * 2 * pi,
          child: CustomPaint(
            size: Size(size + 4, size + 4),
            painter: _ArcRingPainter(
              primaryColor: config.secondaryColor,
              secondaryColor: Colors.transparent,
              strokeWidth: 1.5,
              startAngle: 45,
              sweepAngle: 270,
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleLayer(TierVisualConfig config, double size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size + 14, size + 14),
          painter: _ParticlePainter(
            color: config.secondaryColor,
            phase: _particleController.value * 360,
            particleCount: 6,
          ),
        );
      },
    );
  }

  Widget _buildSparkleLayer(TierVisualConfig config, double size) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size + 12, size + 12),
          painter: _SparklePainter(
            phase: _sparkleController.value * 360,
            sparkleCount: 8,
          ),
        );
      },
    );
  }

  Widget _buildMainAvatar(TierVisualConfig config, double size, double cornerRadius) {
    final hasPhoto = widget.profileImagePath != null &&
        File(widget.profileImagePath!).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          width: config.borderWidth,
          color: config.primaryColor, // Will be overridden by gradient below
        ),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withValues(alpha: config.hasGlow ? 0.5 : 0.3),
            blurRadius: config.hasGlow ? 16 : 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: config.secondaryColor.withValues(alpha: config.hasGlow ? 0.4 : 0.2),
            blurRadius: config.hasGlow ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor.withValues(alpha: 0.2),
            const Color(0xFF0E1512), // DarkBackground
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          border: Border.all(
            width: config.borderWidth,
            color: Colors.transparent,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius - 2),
          child: hasPhoto
              ? Image.file(
                  File(widget.profileImagePath!),
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                )
              : Container(
                  color: const Color(0xFF0E1512),
                  alignment: Alignment.center,
                  child: Text(
                    _defaultEmoji(widget.tierName, config),
                    style: TextStyle(fontSize: size * 0.45),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCornerAccents(TierVisualConfig config, double size) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerAccentPainter(color: config.secondaryColor),
    );
  }

  Widget _buildCrownEmblem(double size) {
    return Positioned(
      top: 0,
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: const Text('👑', style: TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildEditBadge(double size) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF42E5B1), Color(0xFFF59E0B)],
          ),
          border: Border.all(color: const Color(0xFF0E1512), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text('📷', style: TextStyle(fontSize: 14)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMALL TIER AVATAR — Simplified version for top bars (40dp)
// Only shows border color + photo, no animations (perf-friendly)
// ═══════════════════════════════════════════════════════════════

class SmallTierAvatar extends StatelessWidget {
  final String? profileImagePath;
  final String tierName;
  final double sizeDp;

  const SmallTierAvatar({
    super.key,
    this.profileImagePath,
    required this.tierName,
    this.sizeDp = 40,
  });

  @override
  Widget build(BuildContext context) {
    final config = getTierVisualConfig(tierName);
    final cornerRadius = 10.0;
    final effectiveBorderWidth = config.borderWidth > 2 ? 2.0 : config.borderWidth;
    final hasPhoto = profileImagePath != null &&
        File(profileImagePath!).existsSync();

    return Container(
      width: sizeDp,
      height: sizeDp,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          width: effectiveBorderWidth,
          color: config.primaryColor,
        ),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
        color: const Color(0xFF0E1512),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - effectiveBorderWidth),
        child: hasPhoto
            ? Image.file(
                File(profileImagePath!),
                fit: BoxFit.cover,
                width: sizeDp,
                height: sizeDp,
              )
            : Center(
                child: Text(
                  _defaultEmoji(tierName, config),
                  style: TextStyle(fontSize: sizeDp * 0.5),
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTERS — Canvas effects for tiers
// ═══════════════════════════════════════════════════════════════

class _ArcRingPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  _ArcRingPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.9),
          secondaryColor.withValues(alpha: 0.5),
          primaryColor.withValues(alpha: 0.9),
        ],
      ).createShader(rect);

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle * pi / 180,
      sweepAngle * pi / 180,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcRingPainter oldDelegate) => false;
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  final double phase;
  final int particleCount;

  _ParticlePainter({
    required this.color,
    required this.phase,
    required this.particleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = size.width / 2 - 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (phase + i * (360 / particleCount)) * pi / 180;
      final x = center.dx + orbitRadius * cos(angle);
      final y = center.dy + orbitRadius * sin(angle);
      final pAlpha = 0.5 + 0.5 * sin((phase + i * 60) * pi / 180);
      final clampedAlpha = pAlpha.clamp(0.2, 0.9);

      final paint = Paint()
        ..color = color.withValues(alpha: clampedAlpha);

      canvas.drawCircle(Offset(x, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _SparklePainter extends CustomPainter {
  final double phase;
  final int sparkleCount;

  _SparklePainter({
    required this.phase,
    required this.sparkleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < sparkleCount; i++) {
      final seed = i * 45.0;
      final angle = (seed + phase * 0.5) * pi / 180;
      final r = size.width / 2 - 4;
      final cx = size.width / 2 + r * cos(angle);
      final cy = size.height / 2 + r * sin(angle);
      final twinkle = sin((phase + seed) * pi / 180) * 0.5 + 0.5;

      if (twinkle > 0.5) {
        final starSize = 3 + 2 * twinkle;
        final paint = Paint()
          ..color = Colors.white.withValues(alpha: twinkle)
          ..strokeWidth = 1;

        // Horizontal line
        canvas.drawLine(
          Offset(cx - starSize, cy),
          Offset(cx + starSize, cy),
          paint,
        );
        // Vertical line
        canvas.drawLine(
          Offset(cx, cy - starSize),
          Offset(cx, cy + starSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

class _CornerAccentPainter extends CustomPainter {
  final Color color;

  _CornerAccentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const cornerLen = 12.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - cornerLen, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLen), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - cornerLen), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLen, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerAccentPainter oldDelegate) => false;
}
