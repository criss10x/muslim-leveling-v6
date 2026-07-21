import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global light/dark toggle — read by AppColors getters.
/// MUTATION: hanya lewat ThemeNotifier (theme_service.dart), jangan set langsung.
bool _isLight = false;
bool get isLightTheme => _isLight;
set isLightTheme(bool v) => _isLight = v;

/// ── Dark theme colors (original, unchanged) ──
class AppColorsDark {
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

  static const onSurface = Color(0xFFDCE4DE);
  static const onSurfaceVariant = Color(0xFFBACAC1);
  static const onBackground = Color(0xFFDCE4DE);
  static const outline = Color(0xFF85948C);
  static const outlineVariant = Color(0xFF3C4A43);

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

  static const secondary = Color(0xFFFFF9EF);
  static const secondaryContainer = Color(0xFFFFDB3C);
  static const secondaryFixed = Color(0xFFFFE16D);
  static const secondaryFixedDim = Color(0xFFE9C400);
  static const onSecondary = Color(0xFF3A3000);
  static const onSecondaryContainer = Color(0xFF725F00);
  static const onSecondaryFixed = Color(0xFF221B00);
  static const onSecondaryFixedVariant = Color(0xFF544600);

  static const tertiary = Color(0xFF00E1EF);
  static const tertiaryContainer = Color(0xFF00C3CF);
  static const tertiaryFixed = Color(0xFF7DF4FF);
  static const tertiaryFixedDim = Color(0xFF00DBE9);
  static const onTertiary = Color(0xFF00363A);
  static const onTertiaryContainer = Color(0xFF004B50);
  static const onTertiaryFixed = Color(0xFF002022);
  static const onTertiaryFixedVariant = Color(0xFF004F54);

  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
}

/// ── Light theme — solid background, all text black ──
class AppColorsLight {
  // Elevation ramp (redesign light-theme-v2): depth via surface-lightness,
  // tinted toward the emerald brand hue (OKLCH H≈165). Recessed grey canvas,
  // cards climb toward white, chips/tracks sit BELOW cards as insets.
  // Values generated in OKLCH; all text/depth pairs verified WCAG AA.
  static const background = Color(0xFFDDE4E0);              // recessed canvas
  static const surfaceDim = Color(0xFFDDE4E0);
  static const surface = Color(0xFFDDE4E0);
  static const surfaceBright = Color(0xFFDDE4E0);
  static const surfaceContainerLowest = Color(0xFFFBFEFD); // top elevated
  static const surfaceContainerLow = Color(0xFFF5FAF7);    // cards (FlatCard)
  static const surfaceContainer = Color(0xFFF8FCFA);       // panels / glass / hero
  static const surfaceContainerHigh = Color(0xFFD3DBD7);   // chips / tiles / segmented track (inset)
  static const surfaceContainerHighest = Color(0xFFCAD4CF);// progress track (inset)
  static const surfaceVariant = Color(0xFFD3DBD7);

  // Two text tiers (restored): near-black primary + mid-grey secondary.
  static const onSurface = Color(0xFF0E1A15);       // primary text (16.9:1 on card)
  static const onSurfaceVariant = Color(0xFF515F58);// secondary/label text (6.4:1 on card)
  static const onBackground = Color(0xFF0E1A15);
  static const outline = Color(0xFF6D7772);
  static const outlineVariant = Color(0xFFB9C0BC);  // hairline borders/dividers

  // Primary — emerald, for all clickable buttons & highlights
  static const primary = Color(0xFF006C50);
  static const primaryFixed = Color(0xFF4FE7B3);
  static const primaryFixedDim = Color(0xFF32CB9E);
  static const primaryContainer = Color(0xFF8AF8D3);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryFixed = Color(0xFF002116);
  static const onPrimaryFixedVariant = Color(0xFF00513B);
  static const onPrimaryContainer = Color(0xFF002117);
  static const surfaceTint = Color(0xFF006C50);
  static const inversePrimary = Color(0xFF42E5B1);

  // Secondary — warm gold accent
  static const secondary = Color(0xFF7C6600);
  static const secondaryContainer = Color(0xFFFFDE59);
  // Darkened for light: bright gold is used as icon/label text in ~22 places
  // and vanished on light surfaces. #7E5E00 clears AA on canvas AND cards.
  static const secondaryFixed = Color(0xFF7E5E00);
  static const secondaryFixedDim = Color(0xFFE9C400);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF211B00);
  static const onSecondaryFixed = Color(0xFF221B00);
  static const onSecondaryFixedVariant = Color(0xFF544600);

  // Tertiary — cyan accent, darkened so label/border text clears WCAG AA (4.9:1)
  static const tertiary = Color(0xFF11697A);
  static const tertiaryContainer = Color(0xFF4EF0FF);
  static const tertiaryFixed = Color(0xFF9FF5FF);
  static const tertiaryFixedDim = Color(0xFF5DECFA);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF001F23);
  static const onTertiaryFixed = Color(0xFF002022);
  static const onTertiaryFixedVariant = Color(0xFF004F54);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF410002);
}

/// Dynamic AppColors — delegates to dark or light palette based on [_isLight].
/// All 22+ consumer files continue working without changes.
class AppColors {
  static Color get background => _isLight ? AppColorsLight.background : AppColorsDark.background;
  static Color get surfaceDim => _isLight ? AppColorsLight.surfaceDim : AppColorsDark.surfaceDim;
  static Color get surface => _isLight ? AppColorsLight.surface : AppColorsDark.surface;
  static Color get surfaceBright => _isLight ? AppColorsLight.surfaceBright : AppColorsDark.surfaceBright;
  static Color get surfaceContainerLowest => _isLight ? AppColorsLight.surfaceContainerLowest : AppColorsDark.surfaceContainerLowest;
  static Color get surfaceContainerLow => _isLight ? AppColorsLight.surfaceContainerLow : AppColorsDark.surfaceContainerLow;
  static Color get surfaceContainer => _isLight ? AppColorsLight.surfaceContainer : AppColorsDark.surfaceContainer;
  static Color get surfaceContainerHigh => _isLight ? AppColorsLight.surfaceContainerHigh : AppColorsDark.surfaceContainerHigh;
  static Color get surfaceContainerHighest => _isLight ? AppColorsLight.surfaceContainerHighest : AppColorsDark.surfaceContainerHighest;
  static Color get surfaceVariant => _isLight ? AppColorsLight.surfaceVariant : AppColorsDark.surfaceVariant;
  static Color get onSurface => _isLight ? AppColorsLight.onSurface : AppColorsDark.onSurface;
  static Color get onSurfaceVariant => _isLight ? AppColorsLight.onSurfaceVariant : AppColorsDark.onSurfaceVariant;
  static Color get onBackground => _isLight ? AppColorsLight.onBackground : AppColorsDark.onBackground;
  static Color get outline => _isLight ? AppColorsLight.outline : AppColorsDark.outline;
  static Color get outlineVariant => _isLight ? AppColorsLight.outlineVariant : AppColorsDark.outlineVariant;
  static Color get primary => _isLight ? AppColorsLight.primary : AppColorsDark.primary;
  static Color get primaryFixed => _isLight ? AppColorsLight.primaryFixed : AppColorsDark.primaryFixed;
  static Color get primaryFixedDim => _isLight ? AppColorsLight.primaryFixedDim : AppColorsDark.primaryFixedDim;
  static Color get primaryContainer => _isLight ? AppColorsLight.primaryContainer : AppColorsDark.primaryContainer;
  static Color get onPrimary => _isLight ? AppColorsLight.onPrimary : AppColorsDark.onPrimary;
  static Color get onPrimaryFixed => _isLight ? AppColorsLight.onPrimaryFixed : AppColorsDark.onPrimaryFixed;
  static Color get onPrimaryFixedVariant => _isLight ? AppColorsLight.onPrimaryFixedVariant : AppColorsDark.onPrimaryFixedVariant;
  static Color get onPrimaryContainer => _isLight ? AppColorsLight.onPrimaryContainer : AppColorsDark.onPrimaryContainer;
  static Color get surfaceTint => _isLight ? AppColorsLight.surfaceTint : AppColorsDark.surfaceTint;
  static Color get inversePrimary => _isLight ? AppColorsLight.inversePrimary : AppColorsDark.inversePrimary;
  static Color get secondary => _isLight ? AppColorsLight.secondary : AppColorsDark.secondary;
  static Color get secondaryContainer => _isLight ? AppColorsLight.secondaryContainer : AppColorsDark.secondaryContainer;
  static Color get secondaryFixed => _isLight ? AppColorsLight.secondaryFixed : AppColorsDark.secondaryFixed;
  static Color get secondaryFixedDim => _isLight ? AppColorsLight.secondaryFixedDim : AppColorsDark.secondaryFixedDim;
  static Color get onSecondary => _isLight ? AppColorsLight.onSecondary : AppColorsDark.onSecondary;
  static Color get onSecondaryContainer => _isLight ? AppColorsLight.onSecondaryContainer : AppColorsDark.onSecondaryContainer;
  static Color get onSecondaryFixed => _isLight ? AppColorsLight.onSecondaryFixed : AppColorsDark.onSecondaryFixed;
  static Color get onSecondaryFixedVariant => _isLight ? AppColorsLight.onSecondaryFixedVariant : AppColorsDark.onSecondaryFixedVariant;
  static Color get tertiary => _isLight ? AppColorsLight.tertiary : AppColorsDark.tertiary;
  static Color get tertiaryContainer => _isLight ? AppColorsLight.tertiaryContainer : AppColorsDark.tertiaryContainer;
  static Color get tertiaryFixed => _isLight ? AppColorsLight.tertiaryFixed : AppColorsDark.tertiaryFixed;
  static Color get tertiaryFixedDim => _isLight ? AppColorsLight.tertiaryFixedDim : AppColorsDark.tertiaryFixedDim;
  static Color get onTertiary => _isLight ? AppColorsLight.onTertiary : AppColorsDark.onTertiary;
  static Color get onTertiaryContainer => _isLight ? AppColorsLight.onTertiaryContainer : AppColorsDark.onTertiaryContainer;
  static Color get onTertiaryFixed => _isLight ? AppColorsLight.onTertiaryFixed : AppColorsDark.onTertiaryFixed;
  static Color get onTertiaryFixedVariant => _isLight ? AppColorsLight.onTertiaryFixedVariant : AppColorsDark.onTertiaryFixedVariant;
  static Color get error => _isLight ? AppColorsLight.error : AppColorsDark.error;
  static Color get onError => _isLight ? AppColorsLight.onError : AppColorsDark.onError;
  static Color get errorContainer => _isLight ? AppColorsLight.errorContainer : AppColorsDark.errorContainer;
  static Color get onErrorContainer => _isLight ? AppColorsLight.onErrorContainer : AppColorsDark.onErrorContainer;
}

// radius, spacing, text — unchanged
class AppRadius {
  static const xs = 2.0; static const sm = 4.0; static const md = 6.0;
  static const lg = 8.0; static const xl = 12.0; static const xxl = 16.0;
  static const pill = 999.0;
}
class AppSpacing {
  static const base = 4.0; static const xs = 8.0; static const sm = 12.0;
  static const md = 16.0; static const lg = 24.0; static const xl = 32.0;
  static const xxl = 40.0;
}

/// Soft card elevation — LIGHT MODE ONLY. Dark theme gets depth from surface
/// lightness (lighter = raised), so it returns an empty list and stays flat.
class AppShadow {
  static List<BoxShadow> card({double y = 2, double blur = 10, double opacity = 0.07}) {
    if (!isLightTheme) return const [];
    return [
      BoxShadow(
        color: const Color(0xFF0E1A15).withValues(alpha: opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
    ];
  }
}

class AppText {
  static TextStyle displayHero(double size) => GoogleFonts.sora(
        fontSize: size, fontWeight: FontWeight.w800,
        height: size == 40 ? 48 / 40 : 38 / 32,
        letterSpacing: size == 40 ? -0.5 : 0,
      );
  static TextStyle headlineLg() => GoogleFonts.sora(
        fontSize: 32, fontWeight: FontWeight.w700, height: 40 / 32,
      );
  static TextStyle headlineMd() => GoogleFonts.sora(
        fontSize: 24, fontWeight: FontWeight.w700, height: 32 / 24,
      );
  static TextStyle titleLg() => GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20,
      );
  static TextStyle bodyLg() => GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16,
      );
  static TextStyle bodyMd() => GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14,
      );
  static TextStyle labelCaps() => GoogleFonts.jetBrainsMono(
        fontSize: 12, fontWeight: FontWeight.w700, height: 16 / 12, letterSpacing: 1.2,
      );
}

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.background,
      colorScheme: ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.onPrimary,
        primaryContainer: AppColorsDark.primaryContainer,
        onPrimaryContainer: AppColorsDark.onPrimaryContainer,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.onSecondary,
        secondaryContainer: AppColorsDark.secondaryContainer,
        onSecondaryContainer: AppColorsDark.onSecondaryContainer,
        tertiary: AppColorsDark.tertiary,
        onTertiary: AppColorsDark.onTertiary,
        tertiaryContainer: AppColorsDark.tertiaryContainer,
        onTertiaryContainer: AppColorsDark.onTertiaryContainer,
        error: AppColorsDark.error,
        onError: AppColorsDark.onError,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.onSurface,
        surfaceContainerLowest: AppColorsDark.surfaceContainerLowest,
        surfaceContainerLow: AppColorsDark.surfaceContainerLow,
        surfaceContainer: AppColorsDark.surfaceContainer,
        surfaceContainerHigh: AppColorsDark.surfaceContainerHigh,
        surfaceContainerHighest: AppColorsDark.surfaceContainerHighest,
        outline: AppColorsDark.outline,
        outlineVariant: AppColorsDark.outlineVariant,
      ),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.background.withValues(alpha: 0.85),
        elevation: 0,
        titleTextStyle: AppText.titleLg().copyWith(color: AppColorsDark.onSurface),
        iconTheme: const IconThemeData(color: AppColorsDark.onSurface),
      ),
      iconTheme: const IconThemeData(color: AppColorsDark.onSurface),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surfaceContainer,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.onSurfaceVariant,
      ),
    );
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColorsLight.background,
      colorScheme: ColorScheme.light(
        primary: AppColorsLight.primary,
        onPrimary: AppColorsLight.onPrimary,
        primaryContainer: AppColorsLight.primaryContainer,
        onPrimaryContainer: AppColorsLight.onPrimaryContainer,
        secondary: AppColorsLight.secondary,
        onSecondary: AppColorsLight.onSecondary,
        secondaryContainer: AppColorsLight.secondaryContainer,
        onSecondaryContainer: AppColorsLight.onSecondaryContainer,
        tertiary: AppColorsLight.tertiary,
        onTertiary: AppColorsLight.onTertiary,
        tertiaryContainer: AppColorsLight.tertiaryContainer,
        onTertiaryContainer: AppColorsLight.onTertiaryContainer,
        error: AppColorsLight.error,
        onError: AppColorsLight.onError,
        surface: AppColorsLight.surface,
        onSurface: AppColorsLight.onSurface,
        surfaceContainerLowest: AppColorsLight.surfaceContainerLowest,
        surfaceContainerLow: AppColorsLight.surfaceContainerLow,
        surfaceContainer: AppColorsLight.surfaceContainer,
        surfaceContainerHigh: AppColorsLight.surfaceContainerHigh,
        surfaceContainerHighest: AppColorsLight.surfaceContainerHighest,
        outline: AppColorsLight.outline,
        outlineVariant: AppColorsLight.outlineVariant,
      ),
      textTheme: _textTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLight.surface,
        elevation: 0,
        titleTextStyle: AppText.titleLg().copyWith(color: AppColorsLight.onSurface),
        iconTheme: IconThemeData(color: AppColorsLight.onSurface),
      ),
      iconTheme: IconThemeData(color: AppColorsLight.onSurface),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surfaceContainer,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.onSurfaceVariant,
      ),
    );
  }

  static TextTheme _textTheme() => TextTheme(
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
  );
}
