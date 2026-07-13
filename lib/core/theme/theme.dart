import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

class SakTheme {
  const SakTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? SakColors.accentDark : SakColors.accent,
      onPrimary: isDark ? SakColors.backgroundDark : Colors.white,
      secondary: isDark ? SakColors.accentSoftDark : SakColors.accentSoft,
      onSecondary: isDark ? SakColors.accentInkDark : SakColors.accentInk,
      surface: isDark ? SakColors.surfaceDark : SakColors.surface,
      onSurface: isDark ? SakColors.textPrimaryDark : SakColors.textPrimary,
      surfaceContainerLow: isDark
          ? SakColors.surfaceMutedDark
          : SakColors.surfaceMuted,
      surfaceContainerHigh: isDark
          ? SakColors.surfaceDark
          : SakColors.surface,
      outlineVariant: isDark ? SakColors.dividerDark : SakColors.divider,
      error: SakColors.error,
      onError: Colors.white,
    );

    final textTheme = SakTypography.build(brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? SakColors.backgroundDark : SakColors.background,
      textTheme: textTheme,
      fontFamily: SakTypography.body,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(
        color: isDark ? SakColors.dividerDark : SakColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? SakColors.backgroundDark : SakColors.background,
        foregroundColor:
            isDark ? SakColors.textPrimaryDark : SakColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? SakColors.surfaceMutedDark : SakColors.surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? SakColors.textTertiaryDark
              : SakColors.textTertiary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? SakColors.textSecondaryDark
              : SakColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SakRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SakRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SakSpace.lg,
          vertical: SakSpace.md + 2,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? SakColors.surfaceMutedDark : SakColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark
              ? SakColors.textPrimaryDark
              : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SakRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? SakColors.surfaceDark : SakColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SakRadius.md),
          side: BorderSide(
            color: isDark ? SakColors.dividerDark : SakColors.divider,
          ),
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }
}
