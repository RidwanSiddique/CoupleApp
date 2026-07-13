import 'package:flutter/material.dart';

import 'tokens.dart';

/// InstrumentSerif (display) · Inter (body) · Amiri (Arabic).
/// Bundled locally under [assets/fonts/] so the app works fully offline
/// on every platform (no network fetch, no macOS-sandbox surprises).
class SakTypography {
  const SakTypography._();

  static const String _display = 'InstrumentSerif';
  static const String _body = 'Inter';
  static const String _arabic = 'Amiri';

  static TextTheme build({required Brightness brightness}) {
    final baseColor = brightness == Brightness.dark
        ? SakColors.textPrimaryDark
        : SakColors.textPrimary;
    final subColor = brightness == Brightness.dark
        ? SakColors.textSecondaryDark
        : SakColors.textSecondary;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _display,
        fontSize: 44,
        height: 1.1,
        letterSpacing: -0.5,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontFamily: _display,
        fontSize: 34,
        height: 1.15,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontFamily: _display,
        fontSize: 28,
        height: 1.2,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: _display,
        fontSize: 22,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: _body,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: _body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: _body,
        fontSize: 16,
        height: 1.45,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        height: 1.45,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _body,
        fontSize: 12,
        color: subColor,
      ),
      labelLarge: TextStyle(
        fontFamily: _body,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: baseColor,
      ),
    );
  }

  /// Amiri for Arabic text (Qur'an verses, du'a, calligraphy contexts).
  static TextStyle arabic({
    double fontSize = 22,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: _arabic,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: 1.9,
    );
  }
}
