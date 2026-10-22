import 'entry_builder.dart';
import 'quantity.dart';
import 'token.dart';

abstract final class Evaluator {
  /// Evaluates [expression] with × and ÷ before + and −, left to right.
  ///
  /// Returns null for an empty expression. A trailing operator is ignored,
  /// so the live preview works while typing. Throws [CalcException] when
  /// there is no answer.
  static Quantity? evaluate(ParsedExpression expression) {
    final operands = expression.operands;
    if (operands.isEmpty) return null;

    Quantity? total;
    Op? pendingAdd;
    var term = operands.first.quantity;

    for (var i = 1; i < operands.length; i++) {
      final op = expression.operators[i - 1];
      final next = operands[i].quantity;
      if (op.isMultiplicative) {
        term = apply(term, op, next);
      } else {
        total = total == null ? term : apply(total, pendingAdd!, term);
        pendingAdd = op;
        term = next;
      }
    }
    return total == null ? term : apply(total, pendingAdd!, term);
  }

  static Quantity apply(Quantity a, Op op, Quantity b) => switch (op) {
    Op.add => a + b,
    Op.subtract => a - b,
    Op.multiply => a * b,
    Op.divide => a / b,
  };
}
