import 'dart:math' as math;

import '../quantity.dart';
import '../rational.dart';

/// A bag of premixed concrete and how much one bag makes.
final class BagSize {
  const BagSize(this.pounds, this.yieldCubicFeetNum, this.yieldCubicFeetDen);

  static const pounds60 = BagSize(60, 9, 20); // 0.45 cu ft
  static const pounds80 = BagSize(80, 3, 5); // 0.60 cu ft
  static const defaults = [pounds60, pounds80];

  final int pounds;
  final int yieldCubicFeetNum;
  final int yieldCubicFeetDen;

  Rational get yieldCubicFeet => Rational(yieldCubicFeetNum, yieldCubicFeetDen);
}

enum ConcreteShape { slab, column }

/// A pour: a slab or footing (length × width × depth) or a round column
/// (diameter × height). Lengths are in inches.
final class ConcreteInput {
  const ConcreteInput.slab({
    required Rational this.length,
    required Rational this.width,
    required Rational this.depth,
    this.count = 1,
    Rational? wastePercent,
    this.bags = BagSize.defaults,
  }) : shape = ConcreteShape.slab,
       diameter = null,
       height = null,
       _wastePercent = wastePercent;

  const ConcreteInput.column({
    required Rational this.diameter,
    required Rational this.height,
    this.count = 1,
    Rational? wastePercent,
    this.bags = BagSize.defaults,
  }) : shape = ConcreteShape.column,
       length = null,
       width = null,
       depth = null,
       _wastePercent = wastePercent;

  final ConcreteShape shape;
  final Rational? length;
  final Rational? width;
  final Rational? depth;
  final Rational? diameter;
  final Rational? height;

  /// How many identical pours, such as 4 footings.
  final int count;
  final Rational? _wastePercent;
  final List<BagSize> bags;

  Rational get wastePercent => _wastePercent ?? Rational.zero;
}

final class ConcreteResult {
  const ConcreteResult({
    required this.volume,
    required this.volumeWithWaste,
    required this.bagCounts,
  });

  /// Exact volume of all pours.
  final Quantity volume;

  /// [volume] plus the waste allowance. Bags are counted from this.
  final Quantity volumeWithWaste;

  /// Whole bags needed for each bag size, rounded up.
  final List<(BagSize, int)> bagCounts;
}

abstract final class Concrete {
  /// π as a fraction. A column's volume is irrational, so it is accurate
  /// to about 15 digits, far past what any display shows.
  static final Rational pi = Rational.fromDouble(math.pi, places: 15);

  static final Rational _cubicInchesPerCubicFoot = Rational(1728);

  /// Throws [ArgumentError] when a dimension or the count is not positive,
  /// or the waste is negative.
  static ConcreteResult calculate(ConcreteInput input) {
    if (input.count < 1) throw ArgumentError.value(input.count, 'count');
    if (input.wastePercent.isNegative) {
      throw ArgumentError.value(input.wastePercent, 'wastePercent');
    }

    final one = switch (input.shape) {
      ConcreteShape.slab =>
        _positive(input.length!, 'length') *
            _positive(input.width!, 'width') *
            _positive(input.depth!, 'depth'),
      ConcreteShape.column => () {
        final radius = _positive(input.diameter!, 'diameter') / Rational(2);
        return pi * radius * radius * _positive(input.height!, 'height');
      }(),
    };
    final total = one * Rational(input.count);
    final withWaste =
        total * (Rational.one + input.wastePercent / Rational(100));
    final cubicFeet = withWaste / _cubicInchesPerCubicFoot;

    return ConcreteResult(
      volume: Quantity(total, 3),
      volumeWithWaste: Quantity(withWaste, 3),
      bagCounts: [
        for (final bag in input.bags)
          (bag, (cubicFeet / bag.yieldCubicFeet).ceil().toInt()),
      ],
    );
  }

  static Rational _positive(Rational value, String name) {
    if (value <= Rational.zero) throw ArgumentError.value(value, name);
    return value;
  }
}
