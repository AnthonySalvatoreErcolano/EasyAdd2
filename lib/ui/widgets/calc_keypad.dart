import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/token.dart';
import '../../engine/units.dart';
import '../../state/calc_controller.dart';
import '../theme/colors.dart';
import 'key_button.dart';
import 'unit_menu.dart';

/// The main 4 × 5 keypad:
///
///     AC  ⌫  ft  in
///     7   8  9   ÷
///     4   5  6   ×
///     1   2  3   −
///     0   .  =   +
class CalcKeypad extends ConsumerWidget {
  const CalcKeypad({super.key, this.gap = 8});

  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calcProvider);
    final calc = ref.read(calcProvider.notifier);
    bool can(Token t) => calc.canPress(t);

    Widget digit(int d) => KeyButton(
      label: Text('$d'),
      semanticLabel: '$d',
      fontSize: 30,
      enabled: can(DigitToken(d)),
      onPressed: () => calc.pressDigit(d),
    );

    Widget op(Op o, String words) => KeyButton(
      kind: KeyKind.operator,
      label: Text(o.symbol),
      semanticLabel: words,
      fontSize: 34,
      enabled: can(OpToken(o)),
      onPressed: () => calc.pressOp(o),
    );

    Widget unitLabel(String word, String mark, Color markColor) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: word),
          TextSpan(
            text: mark,
            style: TextStyle(color: markColor),
          ),
        ],
      ),
    );

    final rows = <List<Widget>>[
      [
        KeyButton(
          kind: KeyKind.utility,
          label: Text(state.clearLabel),
          semanticLabel: state.clearsEntryOnly ? 'Clear entry' : 'All clear',
          fontSize: 24,
          onPressed: calc.clear,
        ),
        KeyButton(
          kind: KeyKind.utility,
          label: const Text('⌫'),
          semanticLabel: 'Delete',
          fontSize: 26,
          enabled: state.tokens.isNotEmpty || state.isEvaluated,
          onPressed: calc.backspace,
        ),
        KeyButton(
          kind: KeyKind.unit,
          label: unitLabel('ft', '′', AppColors.studRed),
          semanticLabel: 'Feet',
          fontSize: 24,
          enabled: can(const UnitToken(Unit.feet)),
          onPressed: () => calc.pressUnit(Unit.feet),
        ),
        Builder(
          builder: (keyContext) => KeyButton(
            kind: KeyKind.unit,
            label: unitLabel('in', '″', AppColors.chalkDim),
            semanticLabel: 'Inches. Hold for metric units',
            fontSize: 24,
            enabled:
                can(const UnitToken(Unit.inches)) ||
                can(const UnitToken(Unit.millimeters)),
            onPressed: () => calc.pressUnit(Unit.inches),
            onLongPress: () async {
              final unit = await showMetricMenu(keyContext, can);
              if (unit != null) calc.pressUnit(unit);
            },
          ),
        ),
      ],
      [digit(7), digit(8), digit(9), op(Op.divide, 'Divide')],
      [digit(4), digit(5), digit(6), op(Op.multiply, 'Multiply')],
      [digit(1), digit(2), digit(3), op(Op.subtract, 'Minus')],
      [
        digit(0),
        KeyButton(
          label: const Text('.'),
          semanticLabel: 'Decimal point',
          fontSize: 32,
          enabled: can(const DecimalPointToken()),
          onPressed: calc.pressDecimal,
        ),
        KeyButton(
          kind: KeyKind.operator,
          label: const Text('='),
          semanticLabel: 'Equals',
          fontSize: 34,
          enabled:
              state.tokens.isNotEmpty || state.evaluation?.repeatOp != null,
          onPressed: calc.equals,
        ),
        op(Op.add, 'Plus'),
      ],
    ];

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                for (var k = 0; k < rows[r].length; k++) ...[
                  if (k > 0) SizedBox(width: gap),
                  Expanded(child: rows[r][k]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
