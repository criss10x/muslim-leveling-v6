import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';

/// Glass panel — translucent dark surface with subtle border and inner glow.
/// Mirrors the `glass-panel` Tailwind utility used throughout the designs.
/// Set [blurSigma] > 0 for a real frosted-glass backdrop blur (use sparingly —
/// BackdropFilter is expensive, so reserve it for hero surfaces and the nav bar).
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;
  final double blurSigma;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.xl,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadow,
    this.blurSigma = 0,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? AppColors.outlineVariant.withValues(alpha: 0.4),
          width: borderWidth,
        ),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (blurSigma <= 0) return panel;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: panel,
      ),
    );
  }
}

/// HudHeader — header section bahasa desain minimalis (redesign 2026-07):
/// label mono + hairline + meta live (mis. "3/5"). Struktur = informasi.
class HudHeader extends StatelessWidget {
  final String label;
  final String? meta;
  final Color? accent;

  const HudHeader(this.label, {super.key, this.meta, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(label,
              style: AppText.labelCaps().copyWith(color: color, fontSize: 11)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          if (meta != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(meta!,
                style:
                    AppText.labelCaps().copyWith(color: color, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

/// FlatCard — kartu datar standar redesign: surfaceContainerLow, radius 16,
/// tanpa border/shadow. Sorotan (hairline/tint) hanya untuk state bermakna.
class FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: child,
    );
  }
}

/// Entrance — fades and slides a child up into place on first build.
/// Give each section an increasing [delay] for a staggered "HUD boot" feel.
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 450),
    this.offsetY = 24,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _ctl.forward();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// PressableScale — shrinks slightly while pressed, springs back on release.
/// Wrap any tappable card/button for tactile "game button" feedback.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// AnimatedCount — rolls a number toward its new value whenever it changes.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${v.round()}$suffix', style: style),
    );
  }
}

/// ShimmerSweep — a diagonal light band that periodically sweeps across the
/// child. Perfect for "reward ready" states (daily chest, claimable quests).
class ShimmerSweep extends StatefulWidget {
  final Widget child;
  final double radius;
  final Color color;
  final bool enabled;

  const ShimmerSweep({
    super.key,
    required this.child,
    this.radius = AppRadius.xl,
    this.color = Colors.white,
    this.enabled = true,
  });

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    if (widget.enabled) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerSweep old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.enabled && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctl,
                builder: (_, __) {
                  // Band travels from left(-1.5) to right(+1.5); rests between sweeps.
                  final t = Curves.easeInOut.transform(_ctl.value);
                  final dx = -1.5 + 3.0 * t;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(dx - 0.4, -1),
                        end: Alignment(dx + 0.4, 1),
                        colors: [
                          widget.color.withValues(alpha: 0),
                          widget.color.withValues(alpha: 0.10),
                          widget.color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ConfettiBurst — celebratory particles (emerald/gold/cyan) that fall and
/// sway across the child. Runs once; used on the level-up screen.
class ConfettiBurst extends StatefulWidget {
  final Duration duration;
  final int particleCount;

  const ConfettiBurst({
    super.key,
    this.duration = const Duration(milliseconds: 3200),
    this.particleCount = 60,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration)..forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_ctl.value, widget.particleCount),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t; // 0..1
  final int count;
  _ConfettiPainter(this.t, this.count);

  static final _palette = [
    AppColors.primary,
    AppColors.secondaryFixed,
    AppColors.tertiary,
    AppColors.secondaryContainer,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < count; i++) {
      final startX = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final sway = (rnd.nextDouble() - 0.5) * 80;
      final spin = rnd.nextDouble() * math.pi * 6;
      final sizePx = 4 + rnd.nextDouble() * 5;
      final color = _palette[i % _palette.length];
      final delay = rnd.nextDouble() * 0.25;

      final p = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final y = -20 + p * speed * (size.height + 60);
      final x = startX + math.sin(p * math.pi * 3) * sway;
      final fade = p > 0.75 ? (1 - p) / 0.25 : 1.0;

      paint.color = color.withValues(alpha: 0.9 * fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: sizePx, height: sizePx * 0.6),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Hero button — emerald gradient, inner highlight, glow, "gaming" feel.
class HeroButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool expanded;

  const HeroButton({
    super.key,
    required this.label,
    this.trailingIcon,
    this.onPressed,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryFixed],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.headlineMd().copyWith(color: AppColors.onPrimary),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(trailingIcon, color: AppColors.onPrimary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return btn;
  }
}

/// Ghost button — cyan 1px border, transparent background.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.tertiary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: c, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label.toUpperCase(),
                style: AppText.labelCaps().copyWith(color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable background — subtle dark gradient + small floating fireflies.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fireflyController;

  // ponytail: 8 small fireflies, cheap CustomPainter animation
  final List<_Firefly> _fireflies = List.generate(
    8,
    (i) => _Firefly(
      phase: i * 0.6,
      speed: 0.25 + (i % 3) * 0.08,
      color: i.isEven ? AppColors.primary : AppColors.tertiary,
    ),
  );

  @override
  void initState() {
    super.initState();
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    themeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _fireflyController.dispose();
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AppColors.surfaceContainer.withValues(alpha: 0.5),
                  AppColors.background,
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -100,
          child: _blur(AppColors.primary, 300, 0.06),
        ),
        Positioned(
          bottom: -180,
          right: -120,
          child: _blur(AppColors.tertiary, 320, 0.05),
        ),
        AnimatedBuilder(
          animation: _fireflyController,
          builder: (_, __) => CustomPaint(
            painter: _FireflyPainter(
              fireflies: _fireflies,
              time: _fireflyController.value,
            ),
            size: Size.infinite,
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _blur(Color color, double size, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: opacity), blurRadius: 200, spreadRadius: 50),
          ],
        ),
      ),
    );
  }
}

class _Firefly {
  final double phase;
  final double speed;
  final Color color;
  const _Firefly({
    required this.phase,
    required this.speed,
    required this.color,
  });
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  final double time;
  _FireflyPainter({required this.fireflies, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (final f in fireflies) {
      final t = (time * f.speed + f.phase) % 1.0;
      final x = size.width * (0.1 + 0.8 * ((t + f.phase * 0.3) % 1.0));
      final y = size.height * (0.2 + 0.6 * math.sin(t * 2 * math.pi + f.phase));
      final opacity = 0.15 + 0.25 * math.sin(t * 2 * math.pi).abs();
      final paint = Paint()
        ..color = f.color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Soft "neon breathing" wrapper — pulses a colored glow on a child.
class NeonPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final Duration duration;
  const NeonPulse({
    super.key,
    required this.child,
    required this.color,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<NeonPulse> createState() => _NeonPulseState();
}

class _NeonPulseState extends State<NeonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final t = _ctl.value;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3 + 0.2 * t),
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1 + 0.25 * t),
                blurRadius: 5 + 12 * t,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Progress bar — segmented or continuous, with optional animated gradient.
class NeonProgressBar extends StatelessWidget {
  final double progress; // 0..1
  final Color fromColor;
  final Color toColor;
  final double height;
  final bool segmented;
  final int segments;
  final bool leadingGlow; // glow di ujung leading bar (hero rank card)

  NeonProgressBar({
    super.key,
    required this.progress,
    this.fromColor = const Color(0xFF00C897),
    this.toColor = const Color(0xFF42E5B1),
    this.height = 16,
    this.segmented = false,
    this.segments = 5,
    this.leadingGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    if (segmented) {
      return Row(
        children: List.generate(segments, (i) {
          final filled = (i / segments) < p;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: height,
              decoration: BoxDecoration(
                color: filled ? toColor : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(1),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: toColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: p),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animP, _) => _bar(animP),
    );
  }

  Widget _bar(double p) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final fillWidth = barWidth * p;
        final glowSize = height * 1.4;
        final radius = height / 2;
        return SizedBox(
          height: height,
          width: barWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // base bar with rounded corners + border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              // fill gradient (clipped to bar shape)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: p,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [fromColor, toColor]),
                      ),
                    ),
                  ),
                ),
              ),
              // leading-edge glow: bright white spot + halo OUTSIDE clip
              if (leadingGlow && p > 0.0 && p < 1.0)
                Positioned(
                  left: (fillWidth - glowSize / 2).clamp(0.0, barWidth - glowSize),
                  top: -(glowSize - height) / 2,
                  width: glowSize,
                  height: glowSize,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
