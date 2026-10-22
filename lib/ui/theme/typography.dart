import 'package:flutter/painting.dart';

abstract final class AppText {
  static const family = 'Inter';

  /// Tabular figures keep digits the same width, so numbers don't shift as
  /// you type.
  static const _features = [FontFeature.tabularFigures()];

  static TextStyle style(
    double size, {
    FontWeight weight = FontWeight.w500,
    required Color color,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontFeatures: _features,
    height: 1.15,
  );
}
