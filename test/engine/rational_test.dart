import 'package:easyadd/engine/rational.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('construction', () {
    test('reduces and keeps the sign on the numerator', () {
      final r = Rational(6, -8);
      expect(r.numerator, BigInt.from(-3));
      expect(r.denominator, BigInt.from(4));
    });

    test('zero is 0/1', () {
      expect(Rational(0, 5), Rational.zero);
      expect(Rational(0, 5).denominator, BigInt.one);
    });

    test('rejects a zero denominator', () {
      expect(() => Rational(1, 0), throwsArgumentError);
    });

    test('parses typed decimals', () {
      expect(Rational.parseDecimal('12'), Rational(12));
      expect(Rational.parseDecimal('12.'), Rational(12));
      expect(Rational.parseDecimal('0.375'), Rational(3, 8));
      expect(Rational.parseDecimal('.5'), Rational(1, 2));
      expect(Rational.parseDecimal('2.50'), Rational(5, 2));
    });
  });

  group('arithmetic', () {
    test('+ − × ÷ are exact', () {
      expect(Rational(1, 3) + Rational(1, 6), Rational(1, 2));
      expect(Rational(1, 3) - Rational(1, 2), Rational(-1, 6));
      expect(Rational(2, 3) * Rational(9, 4), Rational(3, 2));
      expect(Rational(3, 4) / Rational(3, 8), Rational(2));
      expect(-Rational(5, 7), Rational(-5, 7));
    });

    test('division by zero throws', () {
      expect(() => Rational(1) / Rational.zero, throwsArgumentError);
    });

    test('never overflows on long chains', () {
      var r = Rational.one;
      for (var i = 0; i < 40; i++) {
        r = r * Rational(1000003, 999983);
      }
      for (var i = 0; i < 40; i++) {
        r = r / Rational(1000003, 999983);
      }
      expect(r, Rational.one);
    });
  });

  group('comparison', () {
    test('orders values', () {
      expect(Rational(1, 3) < Rational(1, 2), isTrue);
      expect(Rational(1, 2) <= Rational(2, 4), isTrue);
      expect(Rational(-1, 2) > Rational(-2, 3), isTrue);
      expect(Rational(3, 4) >= Rational(1), isFalse);
      expect(Rational(1, 2).compareTo(Rational(1, 2)), 0);
    });

    test('equality and hashCode follow the reduced value', () {
      expect(Rational(2, 4), Rational(1, 2));
      expect(Rational(2, 4).hashCode, Rational(1, 2).hashCode);
      expect(Rational(1, 2) == Object(), isFalse);
    });

    test('flags', () {
      expect(Rational.zero.isZero, isTrue);
      expect(Rational(-1, 3).isNegative, isTrue);
      expect(Rational(4, 2).isInteger, isTrue);
      expect(Rational(1, 2).isInteger, isFalse);
      expect(Rational(-3, 4).abs(), Rational(3, 4));
      expect(Rational(3, 4).abs(), Rational(3, 4));
    });
  });

  group('rounding', () {
    test('floor goes down, including for negatives', () {
      expect(Rational(7, 2).floor(), BigInt.from(3));
      expect(Rational(-7, 2).floor(), BigInt.from(-4));
      expect(Rational(-4).floor(), BigInt.from(-4));
      expect(Rational(4).floor(), BigInt.from(4));
    });

    test('round sends halves away from zero', () {
      expect(Rational(5, 2).round(), BigInt.from(3));
      expect(Rational(-5, 2).round(), BigInt.from(-3));
      expect(Rational(7, 3).round(), BigInt.from(2));
      expect(Rational(-7, 3).round(), BigInt.from(-2));
    });

    test('ceil goes up, including for negatives', () {
      expect(Rational(7, 2).ceil(), BigInt.from(4));
      expect(Rational(-7, 2).ceil(), BigInt.from(-3));
      expect(Rational(4).ceil(), BigInt.from(4));
    });

    test('fromDouble keeps the requested places', () {
      expect(Rational.fromDouble(0.125), Rational(1, 8));
      expect(Rational.fromDouble(2 / 3, places: 3), Rational(667, 1000));
    });

    test('roundTo snaps to the nearest step', () {
      final sixteenth = Rational(1, 16);
      expect(Rational(60, 7).roundTo(sixteenth), Rational(137, 16));
      expect(Rational(1, 32).roundTo(sixteenth), Rational(1, 16));
      expect(Rational(-1, 32).roundTo(sixteenth), Rational(-1, 16));
    });
  });

  test('toDouble and toString', () {
    expect(Rational(3, 8).toDouble(), 0.375);
    expect(Rational(29, 2).toString(), '29/2');
    expect(Rational(12).toString(), '12');
  });
}
