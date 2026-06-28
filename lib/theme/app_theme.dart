import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nur Quest design tokens from Stitch Muslim Leveling
/// Colors, typography, shapes, spacing — the gaming-Islamic visual language.
class AppColors {
  // Surfaces (deep midnight greens, layered)
  static const background = Color(0xFF0E1512);
  static const surfaceDim = Color(0xFF0E1512);
  static const surface = Color(0xFF0E1512);
  static const surfaceBright = Color(0xFF333B37);
  static const surfaceContainerLowest = Color(0xFF08100C);
  static const surfaceContainerLow = Color(0xFF161D1A);
  static const surfaceContainer = Color(0xFF1A211E);
  static const surfaceContainerHigh = Color(0xFF242C28);
  static const surfaceContainerHighest = Color(0xFF2F3632);
  static const surfaceVariant = Color(0xFF2F3632);

  // Foreground
  static const onSurface = Color(0xFFDCE4DE);
  static const onSurfaceVariant = Color(0xFFBACAC1);
  static const onBackground = Color(0xFFDCE4DE);
  static const outline = Color(0xFF85948C);
  static const outlineVariant = Color(0xFF3C4A43);

  // Primary — Emerald Quest (vitality, growth, success)
  static const primary = Color(0xFF42E5B1);
  static const primaryFixed = Color(0xFF60FCC7);
  static const primaryFixedDim = Color(0xFF3ADFAC);
  static const primaryContainer = Color(0xFF00C897);
  static const onPrimary = Color(0xFF003828);
  static const onPrimaryFixed = Color(0xFF002116);
  static const onPrimaryFixedVariant = Color(0xFF00513B);
  static const onPrimaryContainer = Color(0xFF004D38);
  static const surfaceTint = Color(0xFF3ADFAC);
  static const inversePrimary = Color(0xFF006C50);

  // Secondary — Royal Gold (prestige, mythic rank)
  static const secondary = Color(0xFFFFF9EF);
  static const secondaryContainer = Color(0xFFFFDB3C);
  static const secondaryFixed = Color(0xFFFFE16D);
  static const secondaryFixedDim = Color(0xFFE9C400);
  static const onSecondary = Color(0xFF3A3000);
  static const onSecondaryContainer = Color(0xFF725F00);
  static const onSecondaryFixed = Color(0xFF221B00);
  static const onSecondaryFixedVariant = Color(0xFF544600);

  // Tertiary — Mana Cyan (electric, secondary actions)
  static const tertiary = Color(0xFF00E1EF);
  static const tertiaryContainer = Color(0xFF00C3CF);
  static const tertiaryFixed = Color(0xFF7DF4FF);
  static const tertiaryFixedDim = Color(0xFF00DBE9);
  static const onTertiary = Color(0xFF00363A);
  static const onTertiaryContainer = Color(0xFF004B50);
  static const onTertiaryFixed = Color(0xFF002022);
  static const onTertiaryFixedVariant = Color(0xFF004F54);

  // Error
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
}

class AppRadius {
  static const xs = 2.0;
  static const sm = 4.0;
  static const md = 6.0;
  static const lg = 8.0;
  static const xl = 12.0;
  static const xxl = 16.0;
  static const pill = 999.0;
}

class AppSpacing {
  static const base = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

/// Reusable style helpers wrapping google_fonts. All composable via TextStyle.merge.
class AppText {
  static TextStyle displayHero(double size) => GoogleFonts.sora(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: size == 40 ? 48 / 40 : 38 / 32,
        letterSpacing: size == 40 ? -0.5 : 0,
      );

  static TextStyle headlineLg() => GoogleFonts.sora(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
      );

  static TextStyle headlineMd() => GoogleFonts.sora(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      );

  static TextStyle titleLg() => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      );

  static TextStyle bodyLg() => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle bodyMd() => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  static TextStyle labelCaps() => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 1.2,
      );
}

/// App-wide ThemeData — single dark theme anchored on the Nur Quest palette.
class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: AppText.displayHero(40),
        displayMedium: AppText.displayHero(32),
        headlineLarge: AppText.headlineLg(),
        headlineMedium: AppText.headlineMd(),
        titleLarge: AppText.titleLg(),
        bodyLarge: AppText.bodyLg(),
        bodyMedium: AppText.bodyMd(),
        labelLarge: AppText.labelCaps(),
        labelMedium: AppText.labelCaps(),
        labelSmall: AppText.labelCaps(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withValues(alpha: 0.85),
        elevation: 0,
        titleTextStyle: AppText.titleLg().copyWith(color: AppColors.onSurface),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      iconTheme: const IconThemeData(color: AppColors.onSurface),
    );
  }
}
