import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/calc_controller.dart';
import 'sheets/history_sheet.dart';
import 'sheets/settings_sheet.dart';
import 'theme/colors.dart';
import 'widgets/blade_display.dart';
import 'widgets/calc_keypad.dart';
import 'widgets/fraction_strip.dart';
import 'widgets/memory_row.dart';

/// The calculator. On wide screens (iPad), history stays open beside it.
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const wideBreakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideBreakpoint) {
          return const _CalculatorColumn(showHistoryButton: true);
        }
        return Row(
          children: [
            SizedBox(
              width: math.min(480, constraints.maxWidth * 0.55),
              child: const _CalculatorColumn(showHistoryButton: false),
            ),
            const VerticalDivider(width: 1, color: AppColors.keySteel),
            const Expanded(child: HistoryList()),
          ],
        );
      },
    );
  }
}

class _CalculatorColumn extends ConsumerWidget {
  const _CalculatorColumn({required this.showHistoryButton});

  final bool showHistoryButton;

  // Fixed heights between the blade and the keypad.
  static const _memoryRow = 40.0;
  static const _fractionRow = 48.0;
  static const _gap = 8.0;
  static const _minBlade = 124.0;
  static const _maxBlade = 320.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild on every key press so the fraction keys enable correctly.
    ref.watch(calcProvider);
    final calc = ref.read(calcProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const fixed = _memoryRow + _fractionRow + 4 * _gap;
          final available = constraints.maxHeight - fixed;
          // Keys stop growing at about 84 pt on phones (a bit more on the
          // wider iPad column); extra height goes to the blade.
          final maxKey = (constraints.maxWidth / 4 * 0.85).clamp(84.0, 110.0);
          final maxKeypad = 5 * maxKey + 4 * _gap;
          final keypad = (available - _minBlade).clamp(0.0, maxKeypad);
          final blade = (available - keypad).clamp(0.0, _maxBlade);
          // On tall screens (iPad), the space left over centers the column.
          final slack = available - keypad - blade;
          return Column(
            children: [
              SizedBox(height: _gap + slack / 2),
              SizedBox(height: blade, child: const BladeDisplay()),
              SizedBox(
                height: _memoryRow,
                child: MemoryRow(
                  showHistoryButton: showHistoryButton,
                  onHistory: () => showHistorySheet(context),
                  onSettings: () => showSettingsSheet(context),
                ),
              ),
              SizedBox(
                height: _fractionRow,
                child: FractionStrip(
                  onFraction: calc.pressFraction,
                  canPress: calc.canPress,
                ),
              ),
              const SizedBox(height: _gap),
              SizedBox(
                height: keypad,
                child: const CalcKeypad(gap: _gap),
              ),
              SizedBox(height: _gap + slack / 2),
            ],
          );
        },
      ),
    );
  }
}
