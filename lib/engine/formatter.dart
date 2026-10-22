import 'quantity.dart';
import 'rational.dart';
import 'segment.dart';
import 'units.dart';

final class FormatOptions {
  const FormatOptions({
    this.precision = 16,
    this.lengthDisplay = LengthDisplay.feetInches,
    this.areaUnit = AreaUnit.squareFeet,
    this.volumeUnit = VolumeUnit.cubicFeet,
  }) : assert(
         precision == 2 ||
             precision == 4 ||
             precision == 8 ||
             precision == 16 ||
             precision == 32 ||
             precision == 64,
       );

  /// Lengths round to 1/[precision] of an inch.
  final int precision;
  final LengthDisplay lengthDisplay;
  final AreaUnit areaUnit;
  final VolumeUnit volumeUnit;

  FormatOptions copyWith({
    int? precision,
    LengthDisplay? lengthDisplay,
    AreaUnit? areaUnit,
    VolumeUnit? volumeUnit,
  }) => FormatOptions(
    precision: precision ?? this.precision,
    lengthDisplay: lengthDisplay ?? this.lengthDisplay,
    areaUnit: areaUnit ?? this.areaUnit,
    volumeUnit: volumeUnit ?? this.volumeUnit,
  );
}

final class FormattedValue {
  const FormattedValue(this.segments, {required this.approximate});

  final List<Segment> segments;

  /// True when the shown value was rounded from the exact one.
  final bool approximate;

  String get text => segmentsText(segments);
}

abstract final class Formatter {
  static const numberPlaces = 6;
  static const decimalFeetPlaces = 4;
  static const areaVolumePlaces = 2;

  static const FormattedValue error = FormattedValue([
    ErrorSegment(),
  ], approximate: false);

  static FormattedValue format(
    Quantity quantity, [
    FormatOptions options = const FormatOptions(),
  ]) => switch (quantity.dimension) {
    0 => _decimal(quantity.value, numberPlaces),
    1 => _length(quantity.value, options),
    2 => _decimal(
      quantity.value / options.areaUnit.toSquareInches,
      areaVolumePlaces,
      options.areaUnit.label,
    ),
    _ => _decimal(
      quantity.value / options.volumeUnit.toCubicInches,
      areaVolumePlaces,
      options.volumeUnit.label,
    ),
  };

  static FormattedValue _length(Rational inches, FormatOptions options) =>
      switch (options.lengthDisplay) {
        LengthDisplay.feetInches => _tape(inches, options.precision, true),
        LengthDisplay.inches => _tape(inches, options.precision, false),
        LengthDisplay.decimalFeet => _decimal(
          inches / Rational(12),
          decimalFeetPlaces,
          null,
          const MarkSegment.feet(),
        ),
        LengthDisplay.millimeters => _decimal(
          inches / Unit.millimeters.toInches,
          1,
          'mm',
        ),
        LengthDisplay.centimeters => _decimal(
          inches / Unit.centimeters.toInches,
          2,
          'cm',
        ),
        LengthDisplay.meters => _decimal(inches / Unit.meters.toInches, 3, 'm'),
      };

  /// Tape-measure form: `3' 4 5/8"`, `7 1/2"`, `−1' 0"`.
  static FormattedValue _tape(Rational inches, int precision, bool useFeet) {
    final rounded = inches.roundTo(Rational(1, precision));
    final approximate = rounded != inches;
    final a = rounded.abs();

    final feet = useFeet ? (a / Rational(12)).floor() : BigInt.zero;
    final rest = a - Rational.fromBigInt(feet) * Rational(12);
    final whole = rest.floor();
    final fraction = rest - Rational.fromBigInt(whole);

    return FormattedValue([
      if (approximate) ...const [ApproxSegment(), SpaceSegment()],
      if (rounded.isNegative) const NumberSegment('−'),
      if (feet > BigInt.zero) ...[
        NumberSegment('$feet'),
        const MarkSegment.feet(),
        const SpaceSegment(),
      ],
      if (whole > BigInt.zero || fraction.isZero) NumberSegment('$whole'),
      if (!fraction.isZero) ...[
        if (whole > BigInt.zero) const SpaceSegment(),
        FractionSegment(
          fraction.numerator.toInt(),
          fraction.denominator.toInt(),
        ),
      ],
      const MarkSegment.inches(),
    ], approximate: approximate);
  }

  static FormattedValue _decimal(
    Rational value,
    int places, [
    String? unitLabel,
    MarkSegment? mark,
  ]) {
    final (text, approximate) = decimalText(value, places);
    return FormattedValue([
      if (approximate) ...const [ApproxSegment(), SpaceSegment()],
      NumberSegment(text),
      ?mark,
      if (unitLabel != null) ...[
        const SpaceSegment(),
        MarkSegment.unit(unitLabel),
      ],
    ], approximate: approximate);
  }

  /// [value] as decimal text with at most [places] decimals and thousands
  /// separated by commas. Trailing zeros are removed unless [keepZeros].
  /// Also returns whether the text was rounded.
  static (String, bool) decimalText(
    Rational value,
    int places, {
    bool keepZeros = false,
  }) {
    final scale = BigInt.from(10).pow(places);
    final scaled = (value.abs() * Rational.fromBigInt(scale)).round();
    final approximate = Rational.fromBigInts(scaled, scale) != value.abs();

    final whole = _groupThousands((scaled ~/ scale).toString());
    var decimals = (scaled % scale).toString().padLeft(places, '0');
    if (!keepZeros) decimals = decimals.replaceFirst(RegExp(r'0+$'), '');

    final sign = value.isNegative && scaled != BigInt.zero ? '−' : '';
    final text = decimals.isEmpty ? '$sign$whole' : '$sign$whole.$decimals';
    return (text, approximate);
  }

  /// Dollars and cents, such as `$1,234.50`. Rounds half-cents up.
  static String money(Rational dollars) {
    final (text, _) = decimalText(dollars, 2, keepZeros: true);
    return text.startsWith('−') ? '−\$${text.substring(1)}' : '\$$text';
  }

  static String _groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
