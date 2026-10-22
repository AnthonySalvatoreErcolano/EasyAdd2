import 'rational.dart';

/// Units a length can be typed in. Inches are the base unit.
///
/// Metric factors are exact, because 1 in = 25.4 mm by definition.
enum Unit {
  feet('ft', 12, 1),
  inches('in', 1, 1),
  millimeters('mm', 5, 127),
  centimeters('cm', 50, 127),
  meters('m', 5000, 127);

  const Unit(this.label, this._toInchesNum, this._toInchesDen);

  final String label;
  final int _toInchesNum;
  final int _toInchesDen;

  /// How many inches one of this unit is.
  Rational get toInches => Rational(_toInchesNum, _toInchesDen);

  bool get isMetric =>
      this == millimeters || this == centimeters || this == meters;
}

/// How a length result is shown.
enum LengthDisplay {
  feetInches,
  inches,
  decimalFeet,
  millimeters,
  centimeters,
  meters,
}

/// Units an area result can be shown in. The base unit is square inches.
enum AreaUnit {
  squareInches('sq in', 1, 1),
  squareFeet('sq ft', 144, 1),
  squareYards('sq yd', 1296, 1),
  squareMeters('m²', 25000000, 16129); // (5000/127)²

  const AreaUnit(this.label, this._num, this._den);

  final String label;
  final int _num;
  final int _den;

  /// How many square inches one of this unit is.
  Rational get toSquareInches => Rational(_num, _den);
}

/// Units a volume result can be shown in. The base unit is cubic inches.
enum VolumeUnit {
  cubicInches('cu in', 1, 1),
  cubicFeet('cu ft', 1728, 1),
  cubicYards('cu yd', 46656, 1),
  cubicMeters('m³', 125000000000, 2048383); // (5000/127)³

  const VolumeUnit(this.label, this._num, this._den);

  final String label;
  final int _num;
  final int _den;

  /// How many cubic inches one of this unit is.
  Rational get toCubicInches => Rational(_num, _den);
}
