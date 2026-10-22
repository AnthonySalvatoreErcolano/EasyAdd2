import 'package:easyadd/engine/evaluator.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher throwsCalc(CalcError error) =>
    throwsA(isA<CalcException>().having((e) => e.error, 'error', error));

void main() {
  final inch = Quantity.inches(Rational(1));
  final two = Quantity.number(Rational(2));
  final sqIn = Quantity(Rational(1), 2);
  final cuIn = Quantity(Rational(1), 3);

  test('kind flags', () {
    expect(two.isNumber, isTrue);
    expect(inch.isLength, isTrue);
    expect(sqIn.isArea, isTrue);
    expect(cuIn.isVolume, isTrue);
  });

  group('+ and −', () {
    test('same kinds add', () {
      expect(inch + inch, Quantity.inches(Rational(2)));
      expect(sqIn - sqIn, Quantity(Rational.zero, 2));
    });

    test('a plain number next to a length counts as inches', () {
      expect(two + inch, Quantity.inches(Rational(3)));
      expect(inch - two, Quantity.inches(Rational(-1)));
    });

    test('a length and an area do not mix', () {
      expect(() => inch + sqIn, throwsCalc(CalcError.unitMismatch));
      expect(() => two + sqIn, throwsCalc(CalcError.unitMismatch));
    });
  });

  group('× and ÷', () {
    test('dimensions add when multiplying', () {
      expect((inch * inch).dimension, 2);
      expect((inch * two).dimension, 1);
      expect((sqIn * inch).dimension, 3);
    });

    test('past volume is an error', () {
      expect(() => cuIn * inch, throwsCalc(CalcError.dimensionOverflow));
    });

    test('dimensions subtract when dividing', () {
      expect(sqIn / inch, inch);
      expect((inch / inch).dimension, 0);
    });

    test('a number divided by a length is an error', () {
      expect(() => two / inch, throwsCalc(CalcError.invalidDivision));
    });

    test('dividing by zero is an error', () {
      expect(
        () => inch / Quantity.number(Rational.zero),
        throwsCalc(CalcError.divideByZero),
      );
    });
  });

  test('equality, hashCode and toString', () {
    expect(Quantity.inches(Rational(2, 4)), Quantity.inches(Rational(1, 2)));
    expect(
      Quantity.inches(Rational(1)).hashCode,
      Quantity.inches(Rational(1)).hashCode,
    );
    expect(
      Quantity.inches(Rational(1)) == Quantity.number(Rational(1)),
      isFalse,
    );
    expect(inch.toString(), 'Quantity(1, dim 1)');
    expect(
      const CalcException(CalcError.divideByZero).toString(),
      'CalcException(divideByZero)',
    );
  });

  test('Evaluator.apply covers every operator', () {
    expect(Evaluator.apply(two, Op.add, two), Quantity.number(Rational(4)));
    expect(
      Evaluator.apply(two, Op.subtract, two),
      Quantity.number(Rational.zero),
    );
    expect(
      Evaluator.apply(two, Op.multiply, two),
      Quantity.number(Rational(4)),
    );
    expect(Evaluator.apply(two, Op.divide, two), Quantity.number(Rational.one));
  });

  test('unit factors are exact', () {
    expect(Unit.feet.toInches, Rational(12));
    expect(Unit.millimeters.toInches * Rational(254, 10), Rational.one);
    expect(Unit.meters.toInches, Unit.centimeters.toInches * Rational(100));
    expect(
      AreaUnit.squareMeters.toSquareInches,
      Unit.meters.toInches * Unit.meters.toInches,
    );
    expect(
      VolumeUnit.cubicMeters.toCubicInches,
      Unit.meters.toInches * Unit.meters.toInches * Unit.meters.toInches,
    );
    expect(VolumeUnit.cubicYards.toCubicInches, Rational(36 * 36 * 36));
    expect(Unit.meters.isMetric, isTrue);
    expect(Unit.feet.isMetric, isFalse);
  });
}
