import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/units.dart';
import '../../state/settings_controller.dart';
import '../../state/tool_forms.dart';
import 'tool_widgets.dart';

class ConvertScreen extends ConsumerWidget {
  const ConvertScreen({super.key});

  static const tool = ToolKind.convert;

  static const _labels = {
    LengthDisplay.feetInches: 'Feet & inches',
    LengthDisplay.inches: 'Inches',
    LengthDisplay.decimalFeet: 'Decimal feet',
    LengthDisplay.millimeters: 'Millimeters',
    LengthDisplay.centimeters: 'Centimeters',
    LengthDisplay.meters: 'Meters',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(convertValueProvider);
    final options = ref.watch(settingsProvider).formatOptions;

    return ToolScaffold(
      tool: tool,
      summaryLabel: 'Feet & inches',
      summary: value == null
          ? null
          : Formatter.format(
              value,
              options.copyWith(lengthDisplay: LengthDisplay.feetInches),
            ).segments,
      title: 'Convert',
      result: ResultCard(
        ready: value != null,
        placeholder: 'Type a length in any unit. Hold "in" for metric.',
        rows: value == null
            ? const []
            : [
                for (final mode in LengthDisplay.values)
                  ResultRow(
                    _labels[mode]!,
                    Formatter.format(
                      value,
                      options.copyWith(lengthDisplay: mode),
                    ).segments,
                  ),
              ],
      ),
    );
  }
}
