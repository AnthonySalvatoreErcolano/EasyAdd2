import 'package:easyadd/engine/entry_builder.dart';
import 'package:easyadd/engine/evaluator.dart';
import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/units.dart';

/// Turns readable input into the key presses that type it.
///
/// Words are separated by spaces: `1'` is 1 then ft, `2 1/2"` is 2, the
/// 1/2 key, then in, `10 cm` is 10 then cm, and `+ − × ÷` are operators.
List<Token> keys(String input) {
  final tokens = <Token>[];
  for (final word in input.split(' ').where((w) => w.isNotEmpty)) {
    switch (word) {
      case '+':
        tokens.add(const OpToken(Op.add));
      case '−' || '-':
        tokens.add(const OpToken(Op.subtract));
      case '×' || 'x':
        tokens.add(const OpToken(Op.multiply));
      case '÷':
        tokens.add(const OpToken(Op.divide));
      case 'ft':
        tokens.add(const UnitToken(Unit.feet));
      case 'in':
        tokens.add(const UnitToken(Unit.inches));
      case 'mm':
        tokens.add(const UnitToken(Unit.millimeters));
      case 'cm':
        tokens.add(const UnitToken(Unit.centimeters));
      case 'm':
        tokens.add(const UnitToken(Unit.meters));
      default:
        var body = word;
        Unit? unit;
        if (body.endsWith("'")) {
          unit = Unit.feet;
          body = body.substring(0, body.length - 1);
        } else if (body.endsWith('"')) {
          unit = Unit.inches;
          body = body.substring(0, body.length - 1);
        }
        if (body.contains('/')) {
          final parts = body.split('/');
          tokens.add(FractionToken(int.parse(parts[0]), int.parse(parts[1])));
        } else {
          for (final char in body.split('')) {
            tokens.add(
              char == '.'
                  ? const DecimalPointToken()
                  : DigitToken(int.parse(char)),
            );
          }
        }
        if (unit != null) tokens.add(UnitToken(unit));
    }
  }
  return tokens;
}

/// Exact value of typed input.
Quantity? evaluate(String input) =>
    Evaluator.evaluate(EntryBuilder.parse(keys(input)));

/// Types [input], evaluates it and returns the result as display text.
String calc(String input, [FormatOptions options = const FormatOptions()]) {
  try {
    final result = evaluate(input);
    return result == null ? '' : Formatter.format(result, options).text;
  } on CalcException {
    return Formatter.error.text;
  }
}

/// How the entry line shows typed [input].
String entryText(String input) =>
    EntryBuilder.parse(keys(input)).segments.map((s) => s.text).join();
