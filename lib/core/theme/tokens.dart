import 'package:flutter/material.dart';

/// Design tokens for Sakīnah — Modern Sanctuary palette.
///
/// Cool off-white surfaces, deep-green accent, near-black text.
/// Warm neutrals reserved for Arabic script rendering only.
class SakColors {
  const SakColors._();

  // ---- Light ----
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEEEEA);
  static const Color surfaceSunken = Color(0xFFF2F2EF);
  static const Color accent = Color(0xFF14453D);
  static const Color accentSoft = Color(0xFFDCE6E2);
  static const Color accentInk = Color(0xFF0B2F29);
  static const Color textPrimary = Color(0xFF141613);
  static const Color textSecondary = Color(0xFF5F6A64);
  static const Color textTertiary = Color(0xFF9AA39D);
  static const Color divider = Color(0xFFE4E4DE);
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFA46A22);
  static const Color error = Color(0xFF8A2E36);

  // ---- Dark ----
  static const Color backgroundDark = Color(0xFF0E1210);
  static const Color surfaceDark = Color(0xFF15191A);
  static const Color surfaceMutedDark = Color(0xFF1B1F21);
  static const Color surfaceSunkenDark = Color(0xFF11141B);
  static const Color accentDark = Color(0xFF7FB8A6);
  static const Color accentSoftDark = Color(0xFF1E3630);
  static const Color accentInkDark = Color(0xFFCFE3DC);
  static const Color textPrimaryDark = Color(0xFFEBEBE7);
  static const Color textSecondaryDark = Color(0xFF98A19C);
  static const Color textTertiaryDark = Color(0xFF636B67);
  static const Color dividerDark = Color(0xFF262A2B);
}

class SakSpace {
  const SakSpace._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 72;
}

class SakRadius {
  const SakRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class SakElevation {
  const SakElevation._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0F1611), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

class SakDuration {
  const SakDuration._();
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration gentle = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
}

class SakCurves {
  const SakCurves._();
  // Emphasised gentle-out for entrances
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);
  // Standard for state changes
  static const Curve standard = Cubic(0.4, 0, 0.2, 1);
}
