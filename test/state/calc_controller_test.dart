import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/units.dart';
import 'package:easyadd/state/calc_controller.dart';
import 'package:easyadd/state/calc_state.dart';
import 'package:easyadd/state/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late ProviderContainer c;
  late SharedPreferences prefs;

  setUp(() async {
    (c, prefs) = await makeContainer();
  });

  CalcState state() => c.read(calcProvider);
  CalcController calc() => c.read(calcProvider.notifier);

  group('typing', () {
    test('shows the entry and a live preview once there is an operator', () {
      press(c, '1\' 2 1/2"');
      expect(shown(c), ('1\' 2 1/2"', ''));
      press(c, '+ 3 7/8"');
      expect(shown(c), ('1\' 2 1/2" + 3 7/8"', '1\' 6 3/8"'));
    });

    test('no preview while the expression has no answer', () {
      press(c, '2" ÷ 0');
      expect(shown(c), ('2" ÷ 0', ''));
    });

    test('a second operator replaces the first', () {
      press(c, '2 + ×');
      expect(shown(c).$1, '2 ×');
    });

    test('keys that do not fit are ignored', () {
      press(c, '2 1/2 1/2');
      expect(shown(c).$1, '2 1/2');
      press(c, '+');
      calc().pressOp(Op.add);
      expect(shown(c).$1, '2 1/2 +');
    });

    test('an operator first does nothing', () {
      press(c, '+');
      expect(state().tokens, isEmpty);
    });
  });

  group('equals', () {
    test('shows the expression with = and the result', () {
      press(c, '1\' 2 1/2" + 3 7/8" =');
      expect(shown(c), ('1\' 2 1/2" + 3 7/8" =', '1\' 6 3/8"'));
      expect(state().isEvaluated, isTrue);
    });

    test('repeat-equals applies the last operation again', () {
      press(c, '2\' + 3" =');
      expect(shown(c).$2, '2\' 3"');
      press(c, '=');
      expect(shown(c), ('2\' 3" + 3" =', '2\' 6"'));
      press(c, '=');
      expect(shown(c).$2, '2\' 9"');
    });

    test(
      'repeat-equals follows precedence: 2 + 3 × 4 = = gives 14 then 56',
      () {
        press(c, '2 + 3 × 4 =');
        expect(shown(c).$2, '14');
        press(c, '=');
        expect(shown(c).$2, '56');
      },
    );

    test('a single value with = shows itself and = again does nothing', () {
      press(c, '7 =');
      expect(shown(c), ('7 =', '7'));
      press(c, '=');
      expect(shown(c), ('7 =', '7'));
      expect(state().history, isEmpty);
    });

    test('a trailing operator is dropped', () {
      press(c, '2 + =');
      expect(shown(c), ('2 =', '2'));
    });

    test('= with nothing typed does nothing', () {
      press(c, '=');
      expect(state().isEvaluated, isFalse);
    });

    test('a digit after = starts a new calculation', () {
      press(c, '2 + 3 = 7');
      expect(shown(c), ('7', ''));
    });

    test('a fraction or unit after = also starts fresh', () {
      press(c, '2 + 3 = 1/2');
      expect(shown(c).$1, '1/2');
    });

    test('an operator after = continues from the result', () {
      press(c, '2 + 3 = × 2');
      expect(shown(c), ('5 × 2', '10'));
    });

    test('a continued result keeps full precision', () {
      press(c, '5\' ÷ 7 = × 7 =');
      expect(shown(c).$2, '5\' 0"');
    });

    test('results follow the precision setting', () {
      c.read(settingsProvider.notifier).update((s) => s.copyWith(precision: 8));
      press(c, '5\' ÷ 7 =');
      expect(shown(c).$2, '≈ 8 5/8"');
    });
  });

  group('errors', () {
    setUp(() => press(c, '2" ÷ 0 ='));

    test('show Error under the expression', () {
      expect(shown(c), ('2" ÷ 0 =', 'Error'));
      expect(state().hasError, isTrue);
    });

    test('an operator cannot continue from an error', () {
      expect(calc().canPress(const OpToken(Op.add)), isFalse);
      press(c, '+');
      expect(state().hasError, isTrue);
    });

    test('a digit starts fresh', () {
      press(c, '4');
      expect(shown(c), ('4', ''));
    });

    test('= again does nothing', () {
      press(c, '=');
      expect(shown(c).$2, 'Error');
    });

    test('repeat-equals that goes past volume is an error', () {
      press(c, '1\' × 1\' × 1\' =');
      expect(shown(c).$2, '1 cu ft');
      press(c, '=');
      expect(shown(c), ('1 cu ft × 1\' 0" =', 'Error'));
    });

    test('mixing a length and an area is an error', () {
      press(c, '1\' × 1\' + 1\' =');
      expect(shown(c).$2, 'Error');
    });
  });

  group('backspace', () {
    test('removes one key at a time through every token type', () {
      press(c, '1\' 2 1/2"');
      final steps = <String>[];
      for (var i = 0; i < 5; i++) {
        press(c, '⌫');
        steps.add(shown(c).$1);
      }
      expect(steps, ['1\' 2 1/2', '1\' 2', '1\'', '1', '']);
    });

    test('removes operators and decimal points', () {
      press(c, '2.5 + 3 ⌫');
      expect(shown(c).$1, '2.5 +');
      press(c, '⌫');
      expect(shown(c).$1, '2.5');
      press(c, '⌫');
      expect(shown(c).$1, '2.');
      press(c, '⌫');
      expect(shown(c).$1, '2');
    });

    test('removes a recalled value in one step', () {
      press(c, '2 + 3 = + ⌫');
      expect(shown(c).$1, '5');
      press(c, '⌫');
      expect(shown(c).$1, '');
    });

    test('after = brings the expression back for editing', () {
      press(c, '2 + 3 = ⌫');
      expect(shown(c), ('2 + 3', '5'));
      press(c, '⌫ 4 =');
      expect(shown(c).$2, '6');
    });

    test('does nothing when empty', () {
      press(c, '⌫');
      expect(state().tokens, isEmpty);
    });
  });

  group('clear', () {
    test('C clears the number after an operator, then AC clears all', () {
      press(c, '2 + 3');
      expect(state().clearLabel, 'C');
      press(c, 'C');
      expect(shown(c).$1, '2 +');
      expect(state().clearLabel, 'AC');
      press(c, 'C');
      expect(shown(c).$1, '');
    });

    test('with a single value, the key is AC', () {
      press(c, '25');
      expect(state().clearLabel, 'AC');
      press(c, 'C');
      expect(state().tokens, isEmpty);
    });

    test('after =, AC clears the result', () {
      press(c, '2 + 3 =');
      expect(state().clearLabel, 'AC');
      press(c, 'C');
      expect(state().isEvaluated, isFalse);
      expect(shown(c), ('', ''));
    });

    test('memory survives AC', () {
      press(c, '5 = M+ C');
      expect(state().memory, isNotNull);
    });
  });

  group('memory', () {
    test('M+ and M− add results and MR recalls the total', () {
      press(c, '5 = M+ 3 = M+ 1 = M− MR');
      expect(shown(c).$1, '7');
    });

    test('works with lengths and keeps exact values', () {
      press(c, '1\' = M+ 6" = M− MR');
      expect(shown(c).$1, '6"');
    });

    test('uses the typed value when there is no result', () {
      press(c, '2 1/2" M+ C MR');
      expect(shown(c).$1, '2 1/2"');
    });

    test('ignores a value of a different kind', () {
      press(c, '1\' × 1\' = M+ 2\' = M+ MR');
      expect(shown(c).$1, '1 sq ft');
    });

    test('M+ with nothing to add does nothing', () {
      press(c, 'M+');
      expect(state().memory, isNull);
    });

    test('MR inserts the memory after an operator', () {
      press(c, '4" = M+ C 1\' + MR =');
      expect(shown(c).$2, '1\' 4"');
    });

    test('MR with empty memory does nothing', () {
      press(c, 'MR');
      expect(state().tokens, isEmpty);
    });

    test('MC clears memory', () {
      press(c, '5 = M+ MC');
      expect(state().memory, isNull);
    });

    test('memory is saved and loaded', () async {
      press(c, '1\' 6" = M+');
      expect(prefs.getString('memory.v1'), isNotNull);
      final (reloaded, _) = await makeContainer({
        'memory.v1': prefs.getString('memory.v1')!,
      });
      expect(reloaded.read(calcProvider).memory, Quantity.inches(Rational(18)));
    });
  });

  group('history', () {
    test('each calculation with an operator is saved, newest first', () {
      press(c, '2 + 3 = 1\' × 2 =');
      final history = state().history;
      expect(history, hasLength(2));
      expect(history.first.result, Quantity.inches(Rational(24)));
      expect(history.last.result, Quantity.number(Rational(5)));
    });

    test('repeat-equals adds an entry', () {
      press(c, '2 + 3 = =');
      expect(state().history, hasLength(2));
    });

    test('keeps the last 50', () {
      for (var i = 0; i < 55; i++) {
        press(c, '1 + 1 =');
      }
      expect(state().history, hasLength(CalcState.maxHistory));
    });

    test('a history entry is inserted like a typed value', () {
      press(c, '2 + 3 = C 10 +');
      calc().useHistoryEntry(state().history.single);
      expect(shown(c), ('10 + 5', '15'));
    });

    test('clearHistory empties it', () {
      press(c, '2 + 3 =');
      calc().clearHistory();
      expect(state().history, isEmpty);
    });

    test('history is saved and loaded', () async {
      press(c, '1\' + 2" =');
      final saved = prefs.getString('history.v1');
      expect(saved, isNotNull);
      final (reloaded, _) = await makeContainer({'history.v1': saved!});
      final entry = reloaded.read(calcProvider).history.single;
      expect(entry.result, Quantity.inches(Rational(14)));
      expect(entry.expression.whereType<UnitToken>().first.unit, Unit.feet);
    });
  });

  group('canPress', () {
    test('mirrors what the next key would do', () {
      press(c, '1/2');
      expect(calc().canPress(const FractionToken(1, 2)), isFalse);
      expect(calc().canPress(const FractionToken(1, 8)), isTrue);
      expect(calc().canPress(const DigitToken(3)), isFalse);
      press(c, '+');
      expect(calc().canPress(const OpToken(Op.multiply)), isTrue);
    });

    test('a disabled key after a result leaves the result alone', () {
      press(c, '2 + 3 =');
      calc().pressUnit(Unit.inches);
      expect(shown(c), ('2 + 3 =', '5'));
    });

    test('after a result, digits and operators work', () {
      press(c, '2 + 3 =');
      expect(calc().canPress(const DigitToken(1)), isTrue);
      expect(calc().canPress(const OpToken(Op.add)), isTrue);
      expect(calc().canPress(const UnitToken(Unit.inches)), isFalse);
    });
  });

  test('currentValue is the result, or what is typed', () {
    press(c, '2 + 3');
    expect(state().currentValue, Quantity.number(Rational(5)));
    press(c, '=');
    expect(state().currentValue, Quantity.number(Rational(5)));
  });
}
