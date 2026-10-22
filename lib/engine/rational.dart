/// An exact fraction such as 29/2.
///
/// Always stored reduced, with the sign on the numerator. Uses [BigInt] so
/// long chains of × and ÷ can never overflow.
final class Rational implements Comparable<Rational> {
  factory Rational(int numerator, [int denominator = 1]) =>
      Rational.fromBigInts(BigInt.from(numerator), BigInt.from(denominator));

  factory Rational.fromBigInts(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError.value(denominator, 'denominator', 'must not be 0');
    }
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    final gcd = numerator.gcd(denominator);
    return Rational._(numerator ~/ gcd, denominator ~/ gcd);
  }

  factory Rational.fromBigInt(BigInt value) => Rational._(value, BigInt.one);

  /// The nearest fraction with denominator 10^[places]. Only for results
  /// that are irrational anyway, such as π or a square root.
  factory Rational.fromDouble(double value, {int places = 9}) {
    final scale = BigInt.from(10).pow(places);
    return Rational.fromBigInts(
      BigInt.from((value * scale.toDouble()).round()),
      scale,
    );
  }

  /// Parses typed decimal text such as `12`, `12.` or `0.375`.
  factory Rational.parseDecimal(String text) {
    final dot = text.indexOf('.');
    if (dot < 0) return Rational.fromBigInt(BigInt.parse(text));
    final whole = text.substring(0, dot);
    final fraction = text.substring(dot + 1);
    return Rational.fromBigInts(
      BigInt.parse('${whole.isEmpty ? '0' : whole}$fraction'),
      BigInt.from(10).pow(fraction.length),
    );
  }

  const Rational._(this.numerator, this.denominator);

  static final Rational zero = Rational(0);
  static final Rational one = Rational(1);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;
  bool get isInteger => denominator == BigInt.one;

  Rational operator +(Rational other) => Rational.fromBigInts(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  Rational operator -(Rational other) => this + (-other);

  Rational operator -() => Rational._(-numerator, denominator);

  Rational operator *(Rational other) => Rational.fromBigInts(
    numerator * other.numerator,
    denominator * other.denominator,
  );

  /// Throws [ArgumentError] when [other] is zero.
  Rational operator /(Rational other) => Rational.fromBigInts(
    numerator * other.denominator,
    denominator * other.numerator,
  );

  bool operator <(Rational other) => compareTo(other) < 0;
  bool operator <=(Rational other) => compareTo(other) <= 0;
  bool operator >(Rational other) => compareTo(other) > 0;
  bool operator >=(Rational other) => compareTo(other) >= 0;

  Rational abs() => isNegative ? -this : this;

  /// The largest integer that is not greater than this value.
  BigInt floor() {
    final quotient = numerator ~/ denominator; // truncates toward zero
    final exact = quotient * denominator == numerator;
    return isNegative && !exact ? quotient - BigInt.one : quotient;
  }

  /// The smallest integer that is not less than this value.
  BigInt ceil() => -(-this).floor();

  /// The nearest integer. Exact halves round away from zero.
  BigInt round() {
    final a = abs();
    final rounded =
        (a.numerator * BigInt.two + a.denominator) ~/
        (a.denominator * BigInt.two);
    return isNegative ? -rounded : rounded;
  }

  /// The nearest multiple of [step]. Exact halves round away from zero.
  Rational roundTo(Rational step) =>
      Rational.fromBigInt((this / step).round()) * step;

  double toDouble() => numerator / denominator;

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => isInteger ? '$numerator' : '$numerator/$denominator';
}
