import 'quantity.dart';
import 'units.dart';

enum Op {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const Op(this.symbol);

  final String symbol;

  /// × and ÷ are applied before + and −.
  bool get isMultiplicative => this == multiply || this == divide;
}

/// One key press. The display is built from a list of tokens, and backspace
/// removes the last one.
sealed class Token {
  const Token();
}

final class DigitToken extends Token {
  const DigitToken(this.digit) : assert(digit >= 0 && digit <= 9);

  final int digit;
}

final class DecimalPointToken extends Token {
  const DecimalPointToken();
}

/// A tape-measure fraction key such as 3/8.
final class FractionToken extends Token {
  const FractionToken(this.numerator, this.denominator)
    : assert(numerator > 0 && numerator < denominator);

  final int numerator;
  final int denominator;
}

final class UnitToken extends Token {
  const UnitToken(this.unit);

  final Unit unit;
}

final class OpToken extends Token {
  const OpToken(this.op);

  final Op op;
}

/// A whole value inserted at once: a previous result, memory recall or a
/// history entry. Backspace removes it in one step.
///
/// It is shown with the current format options, so a change of precision
/// or display unit updates it too.
final class ValueToken extends Token {
  const ValueToken(this.quantity);

  final Quantity quantity;
}
