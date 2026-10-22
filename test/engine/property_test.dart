// Random-input checks: 10,000 cases each, with a fixed seed so failures
// can be reproduced.
import 'dart:math';

import 'package:easyadd/engine/entry_builder.dart';
import 'package:easyadd/engine/evaluator.dart';
import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/segment.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

const runs = 10000;

/// A random length between −100 ft and 100 ft, in 1/64ths or 1/7ths.
Rational randomInches(Random random) {
  final den = random.nextBool() ? 64 : 7;
  return Rational(random.nextInt(2400 * den) - 1200 * den, den);
}

/// The key presses that retype a formatted feet-and-inches value.
List<Token> retype(FormattedValue value) {
  final tokens = <Token>[];
  for (final segment in value.segments) {
    switch (segment) {
      case NumberSegment(:final text):
        tokens.addAll(text.split('').map((c) => DigitToken(int.parse(c))));
      case FractionSegment(:final numerator, :final denominator):
        tokens.add(FractionToken(numerator, denominator));
      case MarkSegment(kind: MarkKind.feet):
        tokens.add(const UnitToken(Unit.feet));
      case MarkSegment(kind: MarkKind.inches):
        tokens.add(const UnitToken(Unit.inches));
      default:
        break;
    }
  }
  return tokens;
}

void main() {
  test('a + b − b == a', () {
    final random = Random(1);
    for (var i = 0; i < runs; i++) {
      final a = Quantity.inches(randomInches(random));
      final b = Quantity.inches(randomInches(random));
      expect(a + b - b, a);
    }
  });

  test('(a × n) ÷ n == a', () {
    final random = Random(2);
    for (var i = 0; i < runs; i++) {
      final a = Quantity.inches(randomInches(random));
      final n = Quantity.number(
        Rational(random.nextInt(99) + 1, random.nextInt(9) + 1),
      );
      expect(a * n / n, a);
    }
  });

  test('results land on the precision grid, within half a step', () {
    final random = Random(3);
    for (final precision in [2, 4, 8, 16, 32, 64]) {
      final options = FormatOptions(precision: precision);
      final step = Rational(1, precision);
      for (var i = 0; i < runs ~/ 6; i++) {
        final exact = randomInches(random).abs();
        final shown = Evaluator.evaluate(
          EntryBuilder.parse(
            retype(Formatter.format(Quantity.inches(exact), options)),
          ),
        )!;
        expect((shown.value / step).isInteger, isTrue);
        expect((shown.value - exact).abs() <= step / Rational(2), isTrue);
      }
    }
  });

  test('retyping a formatted result gives the same displayed value', () {
    final random = Random(4);
    for (var i = 0; i < runs; i++) {
      final exact = Quantity.inches(randomInches(random).abs());
      final first = Formatter.format(exact);
      final retyped = Evaluator.evaluate(EntryBuilder.parse(retype(first)))!;
      expect(Formatter.format(retyped).text, first.text.replaceFirst('≈ ', ''));
    }
  });
}
