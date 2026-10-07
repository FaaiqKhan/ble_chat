import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const display = 'Fraunces';
  static const ui = 'Inter';
  static const mono = 'JetBrainsMono';
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 32.0;
  static const pill = 999.0;
}

abstract final class AppTheme {
  static final light = _build(
    brightness: Brightness.light,
    bg: AppColors.bg,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    fg1: AppColors.fg1,
    fg2: AppColors.fg2,
    fg3: AppColors.fg3,
    fg4: AppColors.fg4,
  );

  static final dark = _build(
    brightness: Brightness.dark,
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surface2: AppColors.darkSurface2,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    fg1: AppColors.darkFg1,
    fg2: AppColors.darkFg2,
    fg3: AppColors.darkFg3,
    fg4: AppColors.darkFg4,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surface2,
    required Color border,
    required Color borderStrong,
    required Color fg1,
    required Color fg2,
    required Color fg3,
    required Color fg4,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.cta,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: AppColors.fg1,
      error: AppColors.error,
      onError: Colors.white,
      surface: bg,
      onSurface: fg1,
      onSurfaceVariant: fg3,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface2,
      surfaceContainerHighest: surface2,
      outline: borderStrong,
      outlineVariant: border,
    );

    TextStyle display(double size, [double spacing = 0]) => TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: size >= 32 ? 1.1 : 1.2,
      letterSpacing: size * spacing,
      color: fg1,
    );

    TextStyle body(double size, Color color, {double height = 1.5}) =>
        TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: size,
          height: height,
          color: color,
        );

    final textTheme = TextTheme(
      displayLarge: display(48, -0.02),
      displayMedium: display(40, -0.02),
      displaySmall: display(32, -0.01),
      headlineMedium: display(24),
      headlineSmall: display(20),
      titleLarge: display(18),
      titleMedium: body(
        16,
        fg1,
        height: 1.6,
      ).copyWith(fontWeight: FontWeight.w600),
      titleSmall: body(14, fg1).copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body(16, fg2, height: 1.6),
      bodyMedium: body(14, fg2),
      bodySmall: body(12, fg3),
      labelLarge: body(
        16,
        fg1,
        height: 1.4,
      ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
      labelMedium: body(
        14,
        fg1,
        height: 1.2,
      ).copyWith(fontWeight: FontWeight.w600),
      labelSmall: body(
        11,
        fg3,
        height: 1.2,
      ).copyWith(fontWeight: FontWeight.w600),
    );

    const pill = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: AppFonts.ui,
      textTheme: textTheme,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: fg1,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: display(20),
      ),
      cardTheme: CardThemeData(
        color: bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderStrong,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderStrong,
          elevation: 0,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cta,
          side: const BorderSide(color: AppColors.cta, width: 1.5),
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surface2 : AppColors.primary050,
        labelStyle: body(
          12,
          isDark ? AppColors.primary300 : AppColors.primary,
        ).copyWith(fontWeight: FontWeight.w700),
        side: BorderSide.none,
        shape: pill,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: body(14, fg4),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }
}

/// Monospace style for numerals: dBm values, counters, timers.
TextStyle monoStyle({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color? color,
}) => TextStyle(
  fontFamily: AppFonts.mono,
  fontSize: size,
  fontWeight: weight,
  color: color,
);
