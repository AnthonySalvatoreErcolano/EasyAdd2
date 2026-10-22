import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/rational.dart';
import '../../engine/segment.dart';
import '../../engine/tools/board_feet.dart';
import '../../state/tool_forms.dart';
import 'tool_widgets.dart';

class BoardFeetScreen extends ConsumerWidget {
  const BoardFeetScreen({super.key});

  static const tool = ToolKind.boardFeet;

  /// Board feet to 2 decimals, such as `≈ 3.33 BF`.
  static List<Segment> boardFeet(Rational bf) {
    final (text, approximate) = Formatter.decimalText(bf, 2);
    return [
      if (approximate) ...const [ApproxSegment(), SpaceSegment()],
      NumberSegment(text),
      const SpaceSegment(),
      const MarkSegment.unit('BF'),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(toolFormProvider(tool));
    final r = ref.watch(boardFeetResultProvider);

    return ToolScaffold(
      tool: tool,
      summaryLabel: 'Total',
      summary: r == null
          ? null
          : [
              ...boardFeet(r.totalBoardFeet),
              if (r.totalPrice case final price?) ...[
                const NumberSegment('  ·  '),
                NumberSegment(Formatter.money(price)),
              ],
            ],
      title: 'Board Feet',
      choices: ChoiceBar<String>(
        values: [LumberSizing.nominal.name, LumberSizing.actual.name],
        selected: form.choices[sizingChoice]!,
        label: (v) => v == LumberSizing.nominal.name
            ? 'Nominal (2×6)'
            : 'Actual (1½ × 5½)',
        onSelected: (v) => ref
            .read(toolFormProvider(tool).notifier)
            .setChoice(sizingChoice, v),
      ),
      result: ResultCard(
        ready: r != null,
        headlineLabel: 'Total',
        headline: r == null ? null : boardFeet(r.totalBoardFeet),
        rows: r == null
            ? const []
            : [
                ResultRow('Each board', boardFeet(r.boardFeetEach)),
                if (r.totalPrice case final price?)
                  ResultRow('Total price', [
                    NumberSegment(Formatter.money(price)),
                  ]),
              ],
      ),
    );
  }
}
