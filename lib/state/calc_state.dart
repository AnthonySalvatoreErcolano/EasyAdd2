import '../engine/entry_builder.dart';
import '../engine/evaluator.dart';
import '../engine/formatter.dart';
import '../engine/quantity.dart';
import '../engine/segment.dart';
import '../engine/token.dart';

final class HistoryEntry {
  const HistoryEntry({
    required this.expression,
    required this.result,
    required this.at,
  });

  final List<Token> expression;
  final Quantity result;
  final DateTime at;
}

/// What `=` produced. Shown until the next key press.
final class Evaluation {
  const Evaluation({
    required this.expression,
    this.result,
    this.error,
    this.repeatOp,
    this.repeatOperand,
  }) : assert((result == null) != (error == null));

  /// The expression that was evaluated, shown above the result.
  final List<Token> expression;
  final Quantity? result;
  final CalcError? error;

  /// What another `=` applies to [result]: the last operator and operand.
  final Op? repeatOp;
  final Quantity? repeatOperand;
}

/// What the blade display shows.
final class CalcDisplay {
  const CalcDisplay({
    required this.expression,
    required this.result,
    required this.isFinal,
  });

  /// The top line: what is being typed, or the evaluated expression + `=`.
  final List<Segment> expression;

  /// The big line: the result after `=`, or a live preview while typing.
  /// Null when there is nothing to show.
  final FormattedValue? result;

  /// True after `=`; false for a live preview.
  final bool isFinal;
}

final class CalcState {
  const CalcState({
    this.tokens = const [],
    this.evaluation,
    this.memory,
    this.history = const [],
  });

  /// The entry being typed. Empty while an [evaluation] is shown.
  final List<Token> tokens;
  final Evaluation? evaluation;
  final Quantity? memory;

  /// Newest first.
  final List<HistoryEntry> history;

  static const maxHistory = 50;

  bool get isEvaluated => evaluation != null;

  bool get hasError => evaluation?.error != null;

  /// The value M+ and M− use: the result, or what is typed so far.
  Quantity? get currentValue {
    if (evaluation case final e?) return e.result;
    return _tryEvaluate(tokens);
  }

  /// `C` clears just the number being typed after an operator; `AC` clears
  /// everything except memory.
  bool get clearsEntryOnly =>
      !isEvaluated &&
      tokens.isNotEmpty &&
      tokens.last is! OpToken &&
      tokens.any((t) => t is OpToken);

  String get clearLabel => clearsEntryOnly ? 'C' : 'AC';

  CalcDisplay display(FormatOptions options) {
    if (evaluation case final e?) {
      return CalcDisplay(
        expression: [
          ...EntryBuilder.parse(e.expression, options).segments,
          const SpaceSegment(),
          const EqualsSegment(),
        ],
        result: e.result == null
            ? Formatter.error
            : Formatter.format(e.result!, options),
        isFinal: true,
      );
    }
    final parsed = EntryBuilder.parse(tokens, options);
    // Preview only once there are two values to combine.
    final preview = parsed.operands.length < 2 ? null : _tryEvaluate(tokens);
    return CalcDisplay(
      expression: parsed.segments,
      result: preview == null ? null : Formatter.format(preview, options),
      isFinal: false,
    );
  }

  CalcState copyWith({
    List<Token>? tokens,
    Evaluation? Function()? evaluation,
    Quantity? Function()? memory,
    List<HistoryEntry>? history,
  }) => CalcState(
    tokens: tokens ?? this.tokens,
    evaluation: evaluation == null ? this.evaluation : evaluation(),
    memory: memory == null ? this.memory : memory(),
    history: history ?? this.history,
  );

  static Quantity? _tryEvaluate(List<Token> tokens) {
    try {
      return Evaluator.evaluate(EntryBuilder.parse(tokens));
    } on CalcException {
      return null;
    }
  }
}
