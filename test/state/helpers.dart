import 'package:easyadd/data/prefs_repository.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/state/calc_controller.dart';
import 'package:easyadd/state/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/helpers.dart';

/// A container with in-memory preferences, preloaded with [saved].
Future<(ProviderContainer, SharedPreferences)> makeContainer([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer.test(
    overrides: [
      prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
    ],
  );
  return (container, prefs);
}

/// Presses calculator keys written as text, separated by spaces.
///
/// Besides the words [keys] understands: `=`, `C` (the clear key, C or AC),
/// `⌫`, `M+`, `M−`, `MR` and `MC`.
void press(ProviderContainer container, String input) {
  final calc = container.read(calcProvider.notifier);
  for (final word in input.split(' ').where((w) => w.isNotEmpty)) {
    switch (word) {
      case '=':
        calc.equals();
      case 'C':
        calc.clear();
      case '⌫':
        calc.backspace();
      case 'M+':
        calc.memoryAdd();
      case 'M−':
        calc.memorySubtract();
      case 'MR':
        calc.memoryRecall();
      case 'MC':
        calc.memoryClear();
      default:
        for (final token in keys(word)) {
          switch (token) {
            case DigitToken(:final digit):
              calc.pressDigit(digit);
            case DecimalPointToken():
              calc.pressDecimal();
            case FractionToken(:final numerator, :final denominator):
              calc.pressFraction(numerator, denominator);
            case UnitToken(:final unit):
              calc.pressUnit(unit);
            case OpToken(:final op):
              calc.pressOp(op);
            case ValueToken():
              fail('keys() never makes value tokens');
          }
        }
    }
  }
}

/// The expression line and the result line, as plain text.
(String, String) shown(ProviderContainer container) {
  final options = container.read(settingsProvider).formatOptions;
  final display = container.read(calcProvider).display(options);
  return (
    display.expression.map((s) => s.text).join(),
    display.result?.text ?? '',
  );
}
