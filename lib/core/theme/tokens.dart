import 'package:flutter/material.dart';

/// Design tokens for Sakīnah. Warm neutrals with a single Sakīnah green accent.
class SakColors {
  const SakColors._();

  // Light
  static const Color background = Color(0xFFFBF8F4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3EEE7);
  static const Color accent = Color(0xFF2F6B5C);
  static const Color accentSoft = Color(0xFFDCE9E4);
  static const Color textPrimary = Color(0xFF1F2320);
  static const Color textSecondary = Color(0xFF6E7570);
  static const Color divider = Color(0xFFE7E1D8);
  static const Color success = Color(0xFF3E8E5A);
  static const Color warning = Color(0xFFB77A2C);
  static const Color error = Color(0xFFB0413E);

  // Dark
  static const Color backgroundDark = Color(0xFF141513);
  static const Color surfaceDark = Color(0xFF1C1E1C);
  static const Color surfaceMutedDark = Color(0xFF262927);
  static const Color accentDark = Color(0xFF7FB8A6);
  static const Color accentSoftDark = Color(0xFF25453D);
  static const Color textPrimaryDark = Color(0xFFF1EDE5);
  static const Color textSecondaryDark = Color(0xFFA6ACA5);
  static const Color dividerDark = Color(0xFF2E322F);
}

class SakSpace {
  const SakSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

class SakRadius {
  const SakRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 24;
  static const double pill = 999;
}

class SakElevation {
  const SakElevation._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

class SakDuration {
  const SakDuration._();
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration gentle = Duration(milliseconds: 400);
}
