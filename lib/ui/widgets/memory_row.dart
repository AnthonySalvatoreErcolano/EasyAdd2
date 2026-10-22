import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/calc_controller.dart';
import '../theme/colors.dart';
import 'key_button.dart';

/// MC, MR, M+, M− on the left; history and settings on the right.
class MemoryRow extends ConsumerWidget {
  const MemoryRow({
    super.key,
    required this.onHistory,
    required this.onSettings,
    this.showHistoryButton = true,
  });

  final VoidCallback onHistory;
  final VoidCallback onSettings;

  /// Hidden on iPad, where history is always on screen.
  final bool showHistoryButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calcProvider);
    final calc = ref.read(calcProvider.notifier);
    final hasMemory = state.memory != null;
    final hasValue = state.currentValue != null;

    Widget memKey(String label, String words, bool enabled, VoidCallback f) =>
        SizedBox(
          width: 52,
          child: KeyButton(
            kind: KeyKind.ghost,
            label: Text(label),
            semanticLabel: words,
            fontSize: 16,
            enabled: enabled,
            onPressed: f,
          ),
        );

    return Row(
      children: [
        memKey('MC', 'Memory clear', hasMemory, calc.memoryClear),
        memKey('MR', 'Memory recall', hasMemory, calc.memoryRecall),
        memKey('M+', 'Memory add', hasValue, calc.memoryAdd),
        memKey('M−', 'Memory subtract', hasValue, calc.memorySubtract),
        const Spacer(),
        if (showHistoryButton)
          IconButton(
            tooltip: 'History',
            onPressed: onHistory,
            icon: const Icon(Icons.history, color: AppColors.chalkDim),
          ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: const Icon(Icons.tune, color: AppColors.chalkDim),
        ),
      ],
    );
  }
}
