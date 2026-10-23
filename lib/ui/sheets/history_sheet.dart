import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/entry_builder.dart';
import '../../engine/formatter.dart';
import '../../engine/segment.dart';
import '../../state/calc_controller.dart';
import '../../state/calc_state.dart';
import '../../state/settings_controller.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/measurement_text.dart';

Future<void> showHistorySheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    minChildSize: 0.3,
    maxChildSize: 0.95,
    builder: (_, scroll) => HistoryList(
      scrollController: scroll,
      onPicked: () => Navigator.of(sheetContext).pop(),
    ),
  ),
);

/// Past calculations, newest first. Tapping one puts its result into the
/// calculator. Used in the sheet on phones and as a side panel on iPad.
class HistoryList extends ConsumerWidget {
  const HistoryList({super.key, this.scrollController, this.onPicked});

  final ScrollController? scrollController;
  final VoidCallback? onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(calcProvider.select((s) => s.history));
    final options = ref.watch(settingsProvider).formatOptions;
    final calc = ref.read(calcProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Text(
                'History',
                style: AppText.style(
                  20,
                  weight: FontWeight.w700,
                  color: AppColors.chalkWhite,
                ),
              ),
              const Spacer(),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: calc.clearHistory,
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Your calculations will show up here.',
                      textAlign: TextAlign.center,
                      style: AppText.style(15, color: AppColors.chalkDim),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: AppColors.keySteel,
                  ),
                  itemBuilder: (_, i) => _HistoryTile(
                    entry: history[i],
                    options: options,
                    onTap: () {
                      calc.useHistoryEntry(history[i]);
                      onPicked?.call();
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.options,
    required this.onTap,
  });

  final HistoryEntry entry;
  final FormatOptions options;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expression = [
      ...EntryBuilder.parse(entry.expression, options).segments,
      const SpaceSegment(),
      const EqualsSegment(),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MeasurementText(
              expression,
              style: AppText.style(15, color: AppColors.chalkDim),
              feetColor: AppColors.tapeYellow,
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 34,
              child: MeasurementText(
                Formatter.format(entry.result, options).segments,
                style: AppText.style(
                  28,
                  weight: FontWeight.w700,
                  color: AppColors.chalkWhite,
                ),
                feetColor: AppColors.tapeYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
