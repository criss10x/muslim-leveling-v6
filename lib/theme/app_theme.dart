import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global light/dark toggle — read by AppColors getters.
/// MUTATION: hanya lewat ThemeNotifier (theme_service.dart), jangan set langsung.
bool _isLight = false;
bool get isLightTheme => _isLight;
set isLightTheme(bool v) => _isLight = v;

/// ── Dark theme — pure black canvas + Electric Jade pair ──
/// Canvas = #000000 (true black). Cards keep slight green undertone so
/// elevated surfaces still separate without shadow.
class AppColorsDark {
  static const background = Color(0xFF000000);
  static const surfaceDim = Color(0xFF000000);
  static const surface = Color(0xFF000000);
  static const surfaceBright = Color(0xFF2A2F2C);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerLow = Color(0xFF121816);
  static const surfaceContainer = Color(0xFF161C19);
  static const surfaceContainerHigh = Color(0xFF1E2522);
  static const surfaceContainerHighest = Color(0xFF2A312E);
  static const surfaceVariant = Color(0xFF2A312E);

  static const onSurface = Color(0xFFDCE4DE);
  static const onSurfaceVariant = Color(0xFFBACAC1);
  static const onBackground = Color(0xFFDCE4DE);
  static const outline = Color(0xFF85948C);
  static const outlineVariant = Color(0xFF3C4A43);

  // Bright energy on dark (Strava-loud emerald). onPrimary = deep ink, not white.
  static const primary = Color(0xFF34D399);
  static const primaryFixed = Color(0xFF6EE7B7);
  static const primaryFixedDim = Color(0xFF34D399);
  static const primaryContainer = Color(0xFF047857);
  static const onPrimary = Color(0xFF064E3B);
  static const onPrimaryFixed = Color(0xFF002116);
  static const onPrimaryFixedVariant = Color(0xFF00513B);
  static const onPrimaryContainer = Color(0xFFD1FAE5);
  static const surfaceTint = Color(0xFF34D399);
  static const inversePrimary = Color(0xFF047857);

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

/// ── Light theme — Strava-like neutrals + Electric Jade deep action ──
class AppColorsLight {
  // Strava structure: grey canvas, white cards, black ink, one action color.
  // Brand pair: deep #047857 (light primary) + bright #34D399 (dark primary / fill).
  // Card Δ vs canvas ~1.21 (white on cool grey) — separation is lightness + hairline,
  // not shadow. Deepen canvas only if cards still feel glued after ship.
  //
  // NOTE — M3 name inversion (intentional):
  // High/Highest = darker INSETS (tracks/chips). Low/Lowest = white RAISED cards.
  static const background = Color(0xFFE8EAED);              // recessed canvas
  static const surfaceDim = Color(0xFFE8EAED);
  static const surface = Color(0xFFE8EAED);
  static const surfaceBright = Color(0xFFE8EAED);
  static const surfaceContainerLowest = Color(0xFFFFFFFF); // top elevated
  static const surfaceContainerLow = Color(0xFFFFFFFF);    // cards (FlatCard)
  static const surfaceContainer = Color(0xFFFFFFFF);       // panels
  static const surfaceContainerHigh = Color(0xFFE5E7EB);   // chips / tracks (inset)
  static const surfaceContainerHighest = Color(0xFFD1D5DB);// progress empty
  static const surfaceVariant = Color(0xFFE5E7EB);

  static const onSurface = Color(0xFF1A1A1A);       // body
  static const onSurfaceVariant = Color(0xFF5C6370);// labels
  static const onBackground = Color(0xFF1A1A1A);
  static const outline = Color(0xFF8B929E);         // UI chrome ≥3:1 on white
  static const outlineVariant = Color(0xFFC5CAD3);  // hairlines only

  // Deep action emerald — CTA / nav / progress fill. White-on-primary AA.
  // primaryFixed = bright fill/chrome only, NEVER body text on light.
  static const primary = Color(0xFF047857);
  static const primaryFixed = Color(0xFF34D399);
  static const primaryFixedDim = Color(0xFF10B981);
  static const primaryContainer = Color(0xFFD1FAE5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryFixed = Color(0xFF002116);
  static const onPrimaryFixedVariant = Color(0xFF00513B);
  static const onPrimaryContainer = Color(0xFF064E3B);
  static const surfaceTint = Color(0xFF047857);
  static const inversePrimary = Color(0xFF34D399);

  // Secondary — reward gold (streak / XP)
  // secondaryFixed = gold INK (AA). secondaryFixedDim = gold FILL only.
  static const secondary = Color(0xFF9A6700);
  static const secondaryContainer = Color(0xFFF5D76E);
  static const secondaryFixed = Color(0xFF9A6700);
  static const secondaryFixedDim = Color(0xFFE8B923);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryContainer = Color(0xFF2A1F00);
  static const onSecondaryFixed = Color(0xFF2A1F00);
  static const onSecondaryFixedVariant = Color(0xFF5C4300);

  // Tertiary — live blue (current prayer / HUD now)
  static const tertiary = Color(0xFF0B6E99);
  static const tertiaryContainer = Color(0xFFD7F0FA);
  static const tertiaryFixed = Color(0xFF7DD3F0);    // fill only
  static const tertiaryFixedDim = Color(0xFF2BA3D4);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFF00344A);
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

  /// Gold as icon/label ink (AA). Alias of [secondaryFixed] — honest role name.
  static Color get goldInk => secondaryFixed;
  /// Bright gold fill/chrome only. Alias of [secondaryFixedDim].
  static Color get goldFill => secondaryFixedDim;
  /// Cyan as icon/label ink (AA). Alias of [tertiary].
  static Color get cyanInk => tertiary;
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

/// Card elevation shadows — always empty.
/// Depth comes from the surface lightness ramp (canvas recessed → card raised).
/// Shadow double-counts elevation and violates FlatCard's no-shadow contract.
/// Keep the API so call sites compile; do not reintroduce soft shadows here.
class AppShadow {
  static List<BoxShadow> card({double y = 2, double blur = 10, double opacity = 0.07}) {
    return const [];
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
  /// Small caps label (nav, HUD cells). Prefer this over magic fontSize: 9/11.
  static TextStyle labelCapsSm() => GoogleFonts.jetBrainsMono(
        fontSize: 10, fontWeight: FontWeight.w700, height: 14 / 10, letterSpacing: 1.0,
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
