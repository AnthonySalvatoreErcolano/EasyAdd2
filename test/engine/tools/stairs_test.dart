import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/tools/stairs.dart';
import 'package:flutter_test/flutter_test.dart';

String fmt(Quantity q) => Formatter.format(q).text;

void main() {
  test('rise 8\' 10" with default limits (scaffold table)', () {
    final r = Stairs.calculate(StairInput(totalRise: Rational(106)));
    expect(r.risers, 14);
    expect(fmt(r.riserHeight), '≈ 7 9/16"');
    expect(r.riserHeight.value, Rational(53, 7)); // exact 7.571…
    expect(r.treads, 13);
    expect(fmt(r.treadDepth!), '10"');
    expect(fmt(r.totalRun), '10\' 10"');
    expect(fmt(r.diagonal), '≈ 13\' 11 3/4"');
    expect(r.angleDegrees, closeTo(37.13, 0.01));
    expect(r.warnings, isEmpty);
  });

  test('giving the total run instead of the tread depth', () {
    final r = Stairs.calculate(
      StairInput(totalRise: Rational(106), totalRun: Rational(130)),
    );
    expect(fmt(r.treadDepth!), '10"');
    expect(fmt(r.totalRun), '10\' 10"');
  });

  test('a rise that divides evenly uses the full riser height', () {
    final r = Stairs.calculate(StairInput(totalRise: Rational(31)));
    expect(r.risers, 4);
    expect(fmt(r.riserHeight), '7 3/4"');
  });

  test('a single step has no treads, run or angle', () {
    final r = Stairs.calculate(StairInput(totalRise: Rational(7)));
    expect(r.risers, 1);
    expect(r.treads, 0);
    expect(r.treadDepth, isNull);
    expect(fmt(r.totalRun), '0"');
    expect(fmt(r.diagonal), '7"');
    expect(r.angleDegrees, isNull);
  });

  group('warnings', () {
    test('riser over the code limit', () {
      final r = Stairs.calculate(
        StairInput(totalRise: Rational(24), maxRiser: Rational(8)),
      );
      expect(r.risers, 3);
      expect(fmt(r.riserHeight), '8"');
      expect(r.warnings, {StairWarning.riserTooTall});
    });

    test('tread under the code minimum', () {
      final r = Stairs.calculate(
        StairInput(totalRise: Rational(106), treadDepth: Rational(9)),
      );
      expect(r.warnings, {StairWarning.treadTooShallow});
    });

    test('code limits can be changed', () {
      final r = Stairs.calculate(
        StairInput(
          totalRise: Rational(24),
          maxRiser: Rational(8),
          treadDepth: Rational(9),
          codeMaxRiser: Rational(8),
          codeMinTread: Rational(9),
        ),
      );
      expect(r.warnings, isEmpty);
    });
  });

  group('rejects', () {
    test('a rise or riser limit that is not positive', () {
      expect(
        () => Stairs.calculate(StairInput(totalRise: Rational.zero)),
        throwsArgumentError,
      );
      expect(
        () => Stairs.calculate(
          StairInput(totalRise: Rational(10), maxRiser: Rational(-1)),
        ),
        throwsArgumentError,
      );
    });

    test('a tread or run that is not positive', () {
      expect(
        () => Stairs.calculate(
          StairInput(totalRise: Rational(106), treadDepth: Rational.zero),
        ),
        throwsArgumentError,
      );
      expect(
        () => Stairs.calculate(
          StairInput(totalRise: Rational(106), totalRun: Rational.zero),
        ),
        throwsArgumentError,
      );
    });

    test('a total run for a single step', () {
      expect(
        () => Stairs.calculate(
          StairInput(totalRise: Rational(7), totalRun: Rational(10)),
        ),
        throwsArgumentError,
      );
    });
  });
}
