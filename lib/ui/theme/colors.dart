import 'package:flutter/painting.dart';

/// EasyAdd palette. Tape yellow matches the app icon.
abstract final class AppColors {
  static const tapeYellow = Color(0xFFFEC517);
  static const bladeShadow = Color(0xFFE0A800);
  static const inkBlack = Color(0xFF121212);
  static const caseGraphite = Color(0xFF1E2023);
  static const keySteel = Color(0xFF2E3236);
  static const keySteelPressed = Color(0xFF3C4146);
  static const utilitySteel = Color(0xFF474C53);
  static const utilitySteelPressed = Color(0xFF575D65);
  static const studRed = Color(0xFFD7262E);

  /// Red for text on the yellow blade, dark enough to read (4.8:1).
  static const studRedOnBlade = Color(0xFFA8121A);

  /// Red for text on the dark case and sheets (5.3:1).
  static const studRedOnDark = Color(0xFFFF6B6B);
  static const chalkWhite = Color(0xFFF2F2EE);

  /// Secondary text on the dark case.
  static const chalkDim = Color(0xFF9EA3A8);

  /// Secondary text on the yellow blade.
  static const inkDim = Color(0xFF5C4A00);
}
