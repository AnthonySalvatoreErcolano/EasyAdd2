import 'rational.dart';

/// Why a calculation has no answer.
enum CalcError {
  divideByZero,

  /// Adding or subtracting values of different kinds, such as a length and
  /// an area.
  unitMismatch,

  /// A result past volume, such as length × length × length × length.
  dimensionOverflow,

  /// A division that leaves a negative dimension, such as 4 ÷ 2'.
  invalidDivision,
}

class CalcException implements Exception {
  const CalcException(this.error);

  final CalcError error;

  @override
  String toString() => 'CalcException(${error.name})';
}

/// An exact value with a dimension.
///
/// [dimension] is the power of length: 0 = plain number, 1 = length in
/// inches, 2 = area in square inches, 3 = volume in cubic inches.
final class Quantity {
  const Quantity(this.value, this.dimension)
    : assert(dimension >= 0 && dimension <= maxDimension);

  Quantity.number(Rational value) : this(value, 0);

  Quantity.inches(Rational value) : this(value, 1);

  static const int maxDimension = 3;

  final Rational value;
  final int dimension;

  bool get isNumber => dimension == 0;
  bool get isLength => dimension == 1;
  bool get isArea => dimension == 2;
  bool get isVolume => dimension == 3;

  /// A plain number next to a length counts as inches.
  Quantity operator +(Quantity other) =>
      Quantity(value + other.value, _sumDimension(other));

  Quantity operator -(Quantity other) =>
      Quantity(value - other.value, _sumDimension(other));

  Quantity operator *(Quantity other) {
    final dim = dimension + other.dimension;
    if (dim > maxDimension) {
      throw const CalcException(CalcError.dimensionOverflow);
    }
    return Quantity(value * other.value, dim);
  }

  Quantity operator /(Quantity other) {
    if (other.value.isZero) throw const CalcException(CalcError.divideByZero);
    final dim = dimension - other.dimension;
    if (dim < 0) throw const CalcException(CalcError.invalidDivision);
    return Quantity(value / other.value, dim);
  }

  int _sumDimension(Quantity other) {
    if (dimension == other.dimension) return dimension;
    final pair = {dimension, other.dimension};
    if (pair.contains(0) && pair.contains(1)) return 1;
    throw const CalcException(CalcError.unitMismatch);
  }

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.value == value && other.dimension == dimension;

  @override
  int get hashCode => Object.hash(value, dimension);

  @override
  String toString() => 'Quantity($value, dim $dimension)';
}
