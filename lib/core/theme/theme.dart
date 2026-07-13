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
      onSecondary: isDark ? SakColors.textPrimaryDark : SakColors.textPrimary,
      surface: isDark ? SakColors.surfaceDark : SakColors.surface,
      onSurface: isDark ? SakColors.textPrimaryDark : SakColors.textPrimary,
      surfaceContainerHighest:
          isDark ? SakColors.surfaceMutedDark : SakColors.surfaceMuted,
      error: SakColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? SakColors.backgroundDark : SakColors.background,
      textTheme: SakTypography.build(brightness: brightness),
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
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? SakColors.surfaceMutedDark : SakColors.surfaceMuted,
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
          vertical: SakSpace.md,
        ),
      ),
    );
  }
}
