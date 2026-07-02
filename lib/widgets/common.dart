import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glass panel — translucent dark surface with subtle border and inner glow.
/// Mirrors the `glass-panel` Tailwind utility used throughout the designs.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.xl,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }
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
            gradient: const LinearGradient(
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

/// Reusable background — radial glow blobs + subtle grid texture.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

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
        child,
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

  const NeonProgressBar({
    super.key,
    required this.progress,
    this.fromColor = AppColors.primaryContainer,
    this.toColor = AppColors.primary,
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
