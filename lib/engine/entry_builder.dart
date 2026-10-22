import 'formatter.dart';
import 'quantity.dart';
import 'rational.dart';
import 'segment.dart';
import 'token.dart';
import 'units.dart';

/// One value in an expression, such as `1' 2 1/2"`.
final class Operand {
  const Operand(this.quantity, this.segments);

  final Quantity quantity;
  final List<Segment> segments;
}

/// The operands and operators typed so far.
///
/// There is always one more operand than operators, unless the entry ends
/// with an operator ([endsWithOperator]).
final class ParsedExpression {
  const ParsedExpression(this.operands, this.operators);

  static const empty = ParsedExpression([], []);

  final List<Operand> operands;
  final List<Op> operators;

  bool get isEmpty => operands.isEmpty;

  bool get endsWithOperator =>
      operators.isNotEmpty && operators.length == operands.length;

  List<Segment> get segments => [
    for (var i = 0; i < operands.length; i++) ...[
      ...operands[i].segments,
      if (i < operators.length) ...[
        const SpaceSegment(),
        OperatorSegment(operators[i]),
        if (i + 1 < operands.length) const SpaceSegment(),
      ],
    ],
  ];
}

/// Turns key presses into an expression.
///
/// Rules for one operand:
/// - Digits and `.` build a number; fraction keys add to it.
/// - `ft` closes the feet part; what follows is inches.
/// - `in` or a metric unit closes the operand.
/// - Digits alone, with no unit or fraction, are a plain number. Anything
///   with a fraction or unit is a length.
abstract final class EntryBuilder {
  /// The most digits one number can have.
  static const maxDigits = 9;

  /// Throws [FormatException] when the tokens are not a valid entry.
  /// [options] sets how recalled values ([ValueToken]) are shown.
  static ParsedExpression parse(
    List<Token> tokens, [
    FormatOptions options = const FormatOptions(),
  ]) {
    final operands = <Operand>[];
    final operators = <Op>[];
    var current = _OperandBuilder(options);

    for (final token in tokens) {
      if (token is OpToken) {
        if (current.isEmpty) {
          throw const FormatException('Operator without a value before it');
        }
        operands.add(current.build());
        operators.add(token.op);
        current = _OperandBuilder(options);
      } else {
        current.add(token);
      }
    }
    if (!current.isEmpty) operands.add(current.build());
    return ParsedExpression(operands, operators);
  }

  /// Whether [next] can be typed after [tokens]. Keys that return false are
  /// disabled in the UI.
  static bool canAppend(List<Token> tokens, Token next) {
    try {
      parse([...tokens, next]);
      return true;
    } on FormatException {
      return false;
    }
  }
}

final class _Part {
  const _Part(this.value, this.unit, this.segments);

  final Rational value;
  final Unit unit;
  final List<Segment> segments;
}

final class _OperandBuilder {
  _OperandBuilder(this._options);

  final FormatOptions _options;
  final List<_Part> _parts = [];
  String _digits = '';
  Rational? _fraction;
  ValueToken? _value;
  bool _closed = false;

  bool get isEmpty => _parts.isEmpty && !_hasPending && _value == null;

  bool get _hasPending => _digits.isNotEmpty || _fraction != null;

  bool get _hasPoint => _digits.contains('.');

  void add(Token token) {
    switch (token) {
      case ValueToken():
        _require(isEmpty);
        _value = token;
        _closed = true;
      case DigitToken(:final digit):
        _require(!_closed && _fraction == null);
        _require(_digits.replaceAll('.', '').length < EntryBuilder.maxDigits);
        _digits = _digits == '0' ? '$digit' : '$_digits$digit';
      case DecimalPointToken():
        _require(!_closed && !_hasPoint && _fraction == null);
        _digits = _digits.isEmpty ? '0.' : '$_digits.';
      case FractionToken(:final numerator, :final denominator):
        _require(!_closed && !_hasPoint);
        final sum =
            (_fraction ?? Rational.zero) + Rational(numerator, denominator);
        _require(sum < Rational.one);
        _fraction = sum;
      case UnitToken(:final unit):
        _require(!_closed && _hasPending);
        switch (unit) {
          case Unit.feet:
            _require(_parts.isEmpty && _fraction == null);
          case Unit.inches:
            break; // only feet can come before, and feet never closes
          case Unit.millimeters || Unit.centimeters || Unit.meters:
            _require(_parts.isEmpty && _fraction == null);
        }
        _parts.add(
          _Part(_pendingValue, unit, [..._pendingSegments, ..._mark(unit)]),
        );
        _digits = '';
        _fraction = null;
        _closed = unit != Unit.feet;
      case OpToken():
        // Unreachable: parse() splits on operators before calling add().
        // coverage:ignore-start
        throw StateError('Operators are handled by EntryBuilder.parse');
      // coverage:ignore-end
    }
  }

  Operand build() {
    final value = _value;
    if (value != null) {
      return Operand(
        value.quantity,
        Formatter.format(value.quantity, _options).segments,
      );
    }

    final segments = <Segment>[];
    var inches = Rational.zero;
    for (final part in _parts) {
      if (segments.isNotEmpty) segments.add(const SpaceSegment());
      segments.addAll(part.segments);
      inches += part.value * part.unit.toInches;
    }
    if (!_hasPending) return Operand(Quantity.inches(inches), segments);

    if (segments.isNotEmpty) segments.add(const SpaceSegment());
    segments.addAll(_pendingSegments);
    if (_parts.isEmpty && _fraction == null) {
      return Operand(Quantity.number(_pendingValue), segments);
    }
    return Operand(Quantity.inches(inches + _pendingValue), segments);
  }

  Rational get _pendingValue =>
      (_digits.isEmpty ? Rational.zero : Rational.parseDecimal(_digits)) +
      (_fraction ?? Rational.zero);

  List<Segment> get _pendingSegments {
    final fraction = _fraction;
    return [
      if (_digits.isNotEmpty) NumberSegment(_digits),
      if (fraction != null) ...[
        if (_digits.isNotEmpty) const SpaceSegment(),
        FractionSegment(
          fraction.numerator.toInt(),
          fraction.denominator.toInt(),
        ),
      ],
    ];
  }

  static List<Segment> _mark(Unit unit) => switch (unit) {
    Unit.feet => const [MarkSegment.feet()],
    Unit.inches => const [MarkSegment.inches()],
    _ => [const SpaceSegment(), MarkSegment.unit(unit.label)],
  };

  static void _require(bool condition) {
    if (!condition) throw const FormatException('Key not allowed here');
  }
}
