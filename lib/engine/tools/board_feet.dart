import '../rational.dart';

/// Nominal sizes are what lumber is sold and priced by (a 2×6). Actual
/// sizes are what it measures after drying and planing (1 1/2" × 5 1/2").
enum LumberSizing { nominal, actual }

/// Thickness and width are nominal inches, such as 2 and 6 for a 2×6.
/// Length is in inches.
final class BoardInput {
  const BoardInput({
    required this.thickness,
    required this.width,
    required this.length,
    this.quantity = 1,
    this.pricePerBoardFoot,
    this.sizing = LumberSizing.nominal,
  });

  final Rational thickness;
  final Rational width;
  final Rational length;
  final int quantity;
  final Rational? pricePerBoardFoot;
  final LumberSizing sizing;
}

final class BoardResult {
  const BoardResult({
    required this.boardFeetEach,
    required this.totalBoardFeet,
    required this.totalPrice,
  });

  final Rational boardFeetEach;
  final Rational totalBoardFeet;

  /// Null when no price was given.
  final Rational? totalPrice;
}

abstract final class BoardFeet {
  /// One board foot is 144 cubic inches (12" × 12" × 1").
  static final Rational cubicInchesPerBoardFoot = Rational(144);

  /// Throws [ArgumentError] for a size or quantity that is not positive,
  /// or a negative price.
  static BoardResult calculate(BoardInput input) {
    if (input.quantity < 1) {
      throw ArgumentError.value(input.quantity, 'quantity');
    }
    for (final (value, name) in [
      (input.thickness, 'thickness'),
      (input.width, 'width'),
      (input.length, 'length'),
    ]) {
      if (value <= Rational.zero) throw ArgumentError.value(value, name);
    }
    final price = input.pricePerBoardFoot;
    if (price != null && price.isNegative) {
      throw ArgumentError.value(price, 'pricePerBoardFoot');
    }

    final (thickness, width) = switch (input.sizing) {
      LumberSizing.nominal => (input.thickness, input.width),
      LumberSizing.actual => (
        actualSize(input.thickness),
        actualSize(input.width),
      ),
    };
    final each = thickness * width * input.length / cubicInchesPerBoardFoot;
    final total = each * Rational(input.quantity);
    return BoardResult(
      boardFeetEach: each,
      totalBoardFeet: total,
      totalPrice: price == null ? null : total * price,
    );
  }

  /// The planed size of a nominal dimension: 1 → 3/4, 2–6 → 1/2 less
  /// (2 → 1 1/2, 6 → 5 1/2), 7 and up → 3/4 less (8 → 7 1/4). Sizes that
  /// are not whole inches are taken as already actual.
  static Rational actualSize(Rational nominal) {
    if (!nominal.isInteger) return nominal;
    final n = nominal.numerator.toInt();
    if (n <= 1) return nominal * Rational(3, 4);
    if (n <= 6) return nominal - Rational(1, 2);
    return nominal - Rational(3, 4);
  }
}
