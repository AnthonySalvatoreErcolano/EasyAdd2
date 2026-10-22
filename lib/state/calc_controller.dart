import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_repository.dart';
import '../engine/entry_builder.dart';
import '../engine/evaluator.dart';
import '../engine/quantity.dart';
import '../engine/rational.dart';
import '../engine/token.dart';
import '../engine/units.dart';
import 'calc_state.dart';

final calcProvider = NotifierProvider<CalcController, CalcState>(
  CalcController.new,
);

/// The calculator's keys. Each method is one key press.
class CalcController extends Notifier<CalcState> {
  late PrefsRepository _repo;

  @override
  CalcState build() {
    _repo = ref.read(prefsRepositoryProvider);
    return CalcState(memory: _repo.loadMemory(), history: _repo.loadHistory());
  }

  void pressDigit(int digit) => _input(DigitToken(digit));

  void pressDecimal() => _input(const DecimalPointToken());

  void pressFraction(int numerator, int denominator) =>
      _input(FractionToken(numerator, denominator));

  void pressUnit(Unit unit) => _input(UnitToken(unit));

  void pressOp(Op op) => _input(OpToken(op));

  /// Whether a key does anything right now. Keys that return false are
  /// shown disabled.
  bool canPress(Token token) {
    final s = state;
    if (s.evaluation case final e?) {
      return token is OpToken
          ? e.result != null
          : EntryBuilder.canAppend(const [], token);
    }
    return EntryBuilder.canAppend(s.tokens, token) || _replacesOperator(token);
  }

  void equals() {
    final s = state;
    if (s.evaluation case final e?) {
      _repeat(e);
      return;
    }
    // A trailing operator is dropped: `2 + =` is 2.
    final tokens = [...s.tokens];
    while (tokens.isNotEmpty && tokens.last is OpToken) {
      tokens.removeLast();
    }
    if (tokens.isEmpty) return;

    final parsed = EntryBuilder.parse(tokens);
    try {
      final result = Evaluator.evaluate(parsed)!;
      final hasOp = parsed.operators.isNotEmpty;
      state = s.copyWith(
        tokens: const [],
        evaluation: () => Evaluation(
          expression: tokens,
          result: result,
          repeatOp: hasOp ? parsed.operators.last : null,
          repeatOperand: hasOp ? parsed.operands.last.quantity : null,
        ),
      );
      if (hasOp) _addHistory(tokens, result);
    } on CalcException catch (e) {
      state = s.copyWith(
        tokens: const [],
        evaluation: () => Evaluation(expression: tokens, error: e.error),
      );
    }
  }

  /// Removes the last key press. After `=`, brings the expression back for
  /// editing.
  void backspace() {
    final s = state;
    if (s.evaluation case final e?) {
      state = s.copyWith(tokens: e.expression, evaluation: () => null);
      return;
    }
    if (s.tokens.isEmpty) return;
    state = s.copyWith(tokens: s.tokens.sublist(0, s.tokens.length - 1));
  }

  /// `C` clears the number being typed; `AC` clears everything but memory.
  void clear() {
    final s = state;
    if (s.clearsEntryOnly) {
      final lastOp = s.tokens.lastIndexWhere((t) => t is OpToken);
      state = s.copyWith(tokens: s.tokens.sublist(0, lastOp + 1));
    } else {
      state = s.copyWith(tokens: const [], evaluation: () => null);
    }
  }

  void memoryAdd() => _changeMemory(Op.add);

  void memorySubtract() => _changeMemory(Op.subtract);

  void memoryRecall() {
    final memory = state.memory;
    if (memory != null) _input(ValueToken(memory));
  }

  void memoryClear() {
    state = state.copyWith(memory: () => null);
    _repo.saveMemory(null);
  }

  /// Puts a past result into the entry, as if typed.
  void useHistoryEntry(HistoryEntry entry) => _input(ValueToken(entry.result));

  void clearHistory() {
    state = state.copyWith(history: const []);
    _repo.saveHistory(const []);
  }

  void _input(Token token) {
    if (!canPress(token)) return;
    var s = state;
    if (s.evaluation case final e?) {
      // An operator continues from the result; anything else starts a new
      // calculation.
      s = s.copyWith(
        tokens: token is OpToken ? [ValueToken(e.result!)] : const [],
        evaluation: () => null,
      );
    }
    state = s.copyWith(
      tokens: _replacesOperator(token, s.tokens)
          ? [...s.tokens.sublist(0, s.tokens.length - 1), token]
          : [...s.tokens, token],
    );
  }

  /// Pressing an operator right after another one swaps it.
  bool _replacesOperator(Token token, [List<Token>? tokens]) {
    final t = tokens ?? state.tokens;
    return token is OpToken && t.isNotEmpty && t.last is OpToken;
  }

  void _repeat(Evaluation e) {
    final result = e.result;
    final op = e.repeatOp;
    final operand = e.repeatOperand;
    if (result == null || op == null || operand == null) return;
    final expression = <Token>[
      ValueToken(result),
      OpToken(op),
      ValueToken(operand),
    ];
    try {
      final next = Evaluator.apply(result, op, operand);
      state = state.copyWith(
        evaluation: () => Evaluation(
          expression: expression,
          result: next,
          repeatOp: op,
          repeatOperand: operand,
        ),
      );
      _addHistory(expression, next);
    } on CalcException catch (err) {
      state = state.copyWith(
        evaluation: () => Evaluation(expression: expression, error: err.error),
      );
    }
  }

  void _changeMemory(Op op) {
    final value = state.currentValue;
    if (value == null) return;
    // Empty memory starts at zero of the same kind as the value.
    final memory = state.memory ?? Quantity(Rational.zero, value.dimension);
    try {
      final next = Evaluator.apply(memory, op, value);
      state = state.copyWith(memory: () => next);
      _repo.saveMemory(next);
    } on CalcException {
      // Memory holds a different kind of value, such as an area. Ignore.
    }
  }

  void _addHistory(List<Token> expression, Quantity result) {
    final history = [
      HistoryEntry(expression: expression, result: result, at: DateTime.now()),
      ...state.history,
    ].take(CalcState.maxHistory).toList();
    state = state.copyWith(history: history);
    _repo.saveHistory(history);
  }
}
