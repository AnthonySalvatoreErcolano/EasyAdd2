import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/segment.dart';
import '../../engine/tools/concrete.dart';
import '../../engine/units.dart';
import '../../state/settings_controller.dart';
import '../../state/tool_forms.dart';
import 'tool_widgets.dart';

class ConcreteScreen extends ConsumerWidget {
  const ConcreteScreen({super.key});

  static const tool = ToolKind.concrete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(toolFormProvider(tool));
    final result = ref.watch(concreteResultProvider);
    final options = ref.watch(settingsProvider).formatOptions;
    final waste = form.number(ToolFields.waste);
    final wasteText = waste == null ? '0' : Formatter.decimalText(waste, 1).$1;

    return ToolScaffold(
      tool: tool,
      summaryLabel: 'Concrete to order',
      summary: result == null
          ? null
          : Formatter.format(
              result.volumeWithWaste,
              options.copyWith(volumeUnit: VolumeUnit.cubicYards),
            ).segments,
      title: 'Concrete',
      choices: ChoiceBar<String>(
        values: [ConcreteShape.slab.name, ConcreteShape.column.name],
        selected: form.choices[shapeChoice]!,
        label: (v) =>
            v == ConcreteShape.slab.name ? 'Slab / footing' : 'Round column',
        onSelected: (v) =>
            ref.read(toolFormProvider(tool).notifier).setChoice(shapeChoice, v),
      ),
      result: ResultCard(
        ready: result != null,
        headlineLabel: 'Concrete to order',
        headline: result == null
            ? null
            : Formatter.format(
                result.volumeWithWaste,
                options.copyWith(volumeUnit: VolumeUnit.cubicYards),
              ).segments,
        rows: result == null
            ? const []
            : [
                ResultRow(
                  'Volume',
                  Formatter.format(
                    result.volume,
                    options.copyWith(volumeUnit: VolumeUnit.cubicFeet),
                  ).segments,
                ),
                ResultRow(
                  'With $wasteText% waste',
                  Formatter.format(
                    result.volumeWithWaste,
                    options.copyWith(volumeUnit: VolumeUnit.cubicFeet),
                  ).segments,
                ),
                for (final (bag, count) in result.bagCounts)
                  ResultRow('${bag.pounds} lb bags', [NumberSegment('$count')]),
              ],
      ),
    );
  }
}
