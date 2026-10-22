import 'package:easyadd/engine/entry_builder.dart';
import 'package:easyadd/engine/evaluator.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/segment.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

bool allowed(String typed, Token next) =>
    EntryBuilder.canAppend(keys(typed), next);

void main() {
  group('entry text', () {
    test('shows feet, inches and fractions as typed', () {
      expect(entryText('1\' 2 1/2"'), '1\' 2 1/2"');
      expect(entryText('1\' 2'), '1\' 2');
      expect(entryText('3/8'), '3/8');
      expect(entryText('10 cm'), '10 cm');
    });

    test('two fraction taps add up and reduce', () {
      expect(entryText('2 1/2 1/8'), '2 5/8');
      expect(evaluate('1/2 1/8'), Quantity.inches(Rational(5, 8)));
    });

    test('shows operators between operands and a trailing one', () {
      expect(entryText('1\' + 2"'), '1\' + 2"');
      expect(entryText('1\' +'), '1\' +');
    });

    test('a decimal point with no digits shows a leading zero', () {
      expect(entryText('.'), '0.');
      expect(entryText('. 5'), '0.5');
    });

    test('a leading zero is replaced by the next digit', () {
      expect(entryText('0 7'), '7');
    });
  });

  group('values', () {
    test('digits alone are a plain number', () {
      expect(evaluate('12'), Quantity.number(Rational(12)));
      expect(evaluate('2.5'), Quantity.number(Rational(5, 2)));
    });

    test('a fraction makes a length', () {
      expect(evaluate('2 1/2'), Quantity.inches(Rational(5, 2)));
    });

    test('a number after feet is inches', () {
      expect(evaluate('1\' 6'), Quantity.inches(Rational(18)));
      expect(evaluate('1\''), Quantity.inches(Rational(12)));
    });

    test('metric converts exactly to inches', () {
      expect(evaluate('254 mm'), Quantity.inches(Rational(10)));
      expect(evaluate('2.54 cm'), Quantity.inches(Rational(1)));
      expect(evaluate('1 m'), Quantity.inches(Rational(5000, 127)));
    });

    test('empty input has no value', () {
      expect(EntryBuilder.parse([]).isEmpty, isTrue);
      expect(Evaluator.evaluate(ParsedExpression.empty), isNull);
    });

    test('a trailing operator is ignored for the preview', () {
      final parsed = EntryBuilder.parse(keys('1\' +'));
      expect(parsed.endsWithOperator, isTrue);
      expect(Evaluator.evaluate(parsed), Quantity.inches(Rational(12)));
    });

    test('a recalled value acts as one operand', () {
      final value = ValueToken(Quantity.inches(Rational(30)), const [
        NumberSegment('2'),
        MarkSegment.feet(),
        SpaceSegment(),
        NumberSegment('6'),
        MarkSegment.inches(),
      ]);
      final parsed = EntryBuilder.parse([value, ...keys('+ 6"')]);
      expect(segmentsText(parsed.segments), '2\' 6" + 6"');
      expect(Evaluator.evaluate(parsed), Quantity.inches(Rational(36)));
    });
  });

  group('keys that are refused', () {
    test('an operator first, or two in a row', () {
      expect(allowed('', const OpToken(Op.add)), isFalse);
      expect(allowed('2 +', const OpToken(Op.multiply)), isFalse);
      expect(() => EntryBuilder.parse(keys('+ 2')), throwsFormatException);
    });

    test('a unit with nothing before it', () {
      expect(allowed('', const UnitToken(Unit.feet)), isFalse);
      expect(allowed('1\'', const UnitToken(Unit.inches)), isFalse);
    });

    test('feet twice, or feet after inches or a fraction', () {
      expect(allowed('1\' 2', const UnitToken(Unit.feet)), isFalse);
      expect(allowed('2"', const DigitToken(1)), isFalse);
      expect(allowed('1/2', const UnitToken(Unit.feet)), isFalse);
    });

    test('a digit after a fraction', () {
      expect(allowed('2 1/2', const DigitToken(3)), isFalse);
    });

    test('a second decimal point, or a point after a fraction', () {
      expect(allowed('2.5', const DecimalPointToken()), isFalse);
      expect(allowed('1/2', const DecimalPointToken()), isFalse);
    });

    test('a fraction after a decimal point', () {
      expect(allowed('2.5', const FractionToken(1, 2)), isFalse);
    });

    test('fractions that would reach a whole inch', () {
      expect(allowed('1/2', const FractionToken(1, 2)), isFalse);
      expect(allowed('1/2', const FractionToken(7, 16)), isTrue);
    });

    test('metric mixed with feet or fractions, or after another unit', () {
      expect(allowed('1\' 2', const UnitToken(Unit.centimeters)), isFalse);
      expect(allowed('1/2', const UnitToken(Unit.millimeters)), isFalse);
      expect(allowed('10 cm', const DigitToken(5)), isFalse);
    });

    test('more than the maximum number of digits', () {
      expect(allowed('123456789', const DigitToken(1)), isFalse);
      expect(allowed('12345678', const DigitToken(9)), isTrue);
      expect(allowed('1234.5678', const DigitToken(9)), isTrue);
    });

    test('anything after a recalled value except an operator', () {
      final value = ValueToken(Quantity.inches(Rational(1)), const []);
      expect(EntryBuilder.canAppend([value], const DigitToken(1)), isFalse);
      expect(EntryBuilder.canAppend([value], value), isFalse);
      expect(EntryBuilder.canAppend([value], const OpToken(Op.add)), isTrue);
    });
  });
}
