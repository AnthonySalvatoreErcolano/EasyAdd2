import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/rational.dart';
import '../../engine/tools/board_feet.dart';
import '../../engine/tools/concrete.dart';
import '../../engine/units.dart';
import '../../state/settings.dart';
import '../../state/settings_controller.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/stacked_fraction.dart';

const appVersion = '2.0.0';

Future<void> showSettingsSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      const FractionallySizedBox(heightFactor: 0.92, child: SettingsPanel()),
);

class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    void set(Settings Function(Settings) change) => notifier.update(change);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Settings',
          style: AppText.style(
            20,
            weight: FontWeight.w700,
            color: AppColors.chalkWhite,
          ),
        ),
        const _Section('Round lengths to the nearest'),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (final p in Settings.precisions)
                ButtonSegment(
                  value: p,
                  label: FittedBox(
                    child: StackedFraction(
                      numerator: 1,
                      denominator: p,
                      style: AppText.style(
                        20,
                        weight: FontWeight.w600,
                        color: p == s.precision
                            ? AppColors.inkBlack
                            : AppColors.chalkWhite,
                      ),
                    ),
                  ),
                ),
            ],
            selected: {s.precision},
            onSelectionChanged: (v) =>
                set((s) => s.copyWith(precision: v.first)),
          ),
        ),
        const _Section('Show lengths as'),
        _Choices<LengthDisplay>(
          values: LengthDisplay.values,
          selected: s.lengthDisplay,
          label: (v) => switch (v) {
            LengthDisplay.feetInches => 'Feet & inches',
            LengthDisplay.inches => 'Inches',
            LengthDisplay.decimalFeet => 'Decimal feet',
            LengthDisplay.millimeters => 'mm',
            LengthDisplay.centimeters => 'cm',
            LengthDisplay.meters => 'm',
          },
          onSelected: (v) => set((s) => s.copyWith(lengthDisplay: v)),
        ),
        const _Section('Show areas in'),
        _Choices<AreaUnit>(
          values: const [
            AreaUnit.squareFeet,
            AreaUnit.squareYards,
            AreaUnit.squareMeters,
            AreaUnit.squareInches,
          ],
          selected: s.areaUnit,
          label: (v) => v.label,
          onSelected: (v) => set((s) => s.copyWith(areaUnit: v)),
        ),
        const _Section('Show volumes in'),
        _Choices<VolumeUnit>(
          values: const [
            VolumeUnit.cubicFeet,
            VolumeUnit.cubicYards,
            VolumeUnit.cubicMeters,
            VolumeUnit.cubicInches,
          ],
          selected: s.volumeUnit,
          label: (v) => v.label,
          onSelected: (v) => set((s) => s.copyWith(volumeUnit: v)),
        ),
        const _Section('Lumber sizes'),
        _Choices<LumberSizing>(
          values: LumberSizing.values,
          selected: s.lumberSizing,
          label: (v) => switch (v) {
            LumberSizing.nominal => 'Nominal (2×6)',
            LumberSizing.actual => 'Actual (1½ × 5½)',
          },
          onSelected: (v) => set((s) => s.copyWith(lumberSizing: v)),
        ),
        const _Section('Concrete bags'),
        for (var i = 0; i < s.bags.length; i++)
          _ValueTile(
            title: '${s.bags[i].pounds} lb bag',
            value: '${_decimal(s.bags[i].yieldCubicFeet)} cu ft',
            onTap: () async {
              final yieldCuFt = await _askNumber(
                context,
                title: '${s.bags[i].pounds} lb bag yield',
                suffix: 'cu ft',
                initial: s.bags[i].yieldCubicFeet,
              );
              if (yieldCuFt == null) return;
              final bags = [...s.bags];
              bags[i] = BagSize(
                bags[i].pounds,
                yieldCuFt.numerator.toInt(),
                yieldCuFt.denominator.toInt(),
              );
              set((s) => s.copyWith(bags: bags));
            },
          ),
        const _Section('Stair code limits'),
        _ValueTile(
          title: 'Max riser height',
          value: '${_decimal(s.codeMaxRiser)} in',
          onTap: () async {
            final v = await _askNumber(
              context,
              title: 'Max riser height',
              suffix: 'in',
              initial: s.codeMaxRiser,
            );
            if (v != null) set((s) => s.copyWith(codeMaxRiser: v));
          },
        ),
        _ValueTile(
          title: 'Min tread depth',
          value: '${_decimal(s.codeMinTread)} in',
          onTap: () async {
            final v = await _askNumber(
              context,
              title: 'Min tread depth',
              suffix: 'in',
              initial: s.codeMinTread,
            );
            if (v != null) set((s) => s.copyWith(codeMinTread: v));
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Key vibration'),
          value: s.haptics,
          onChanged: (v) => set((s) => s.copyWith(haptics: v)),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _confirmReset(context, notifier),
            child: const Text(
              'Reset all settings',
              style: TextStyle(color: AppColors.studRedOnDark),
            ),
          ),
        ),
        Center(
          child: Text(
            'EasyAdd $appVersion',
            style: AppText.style(13, color: AppColors.chalkDim),
          ),
        ),
      ],
    );
  }

  static String _decimal(Rational r) => Formatter.decimalText(r, 4).$1;

  static Future<void> _confirmReset(
    BuildContext context,
    SettingsController notifier,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset all settings?'),
        content: const Text('History and memory are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok ?? false) notifier.reset();
  }

  /// Asks for a positive decimal number, such as 0.6 or 7.75.
  static Future<Rational?> _askNumber(
    BuildContext context, {
    required String title,
    required String suffix,
    required Rational initial,
  }) async {
    final controller = TextEditingController(text: _decimal(initial));
    final valid = RegExp(r'^\d*\.?\d+$|^\d+\.$');
    Rational? parse() {
      final text = controller.text.trim();
      if (!valid.hasMatch(text)) return null;
      final value = Rational.parseDecimal(text);
      return value > Rational.zero ? value : null;
    }

    final result = await showDialog<Rational>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: suffix,
              errorText: parse() == null ? 'Enter a number above 0' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: parse() == null
                  ? null
                  : () => Navigator.pop(c, parse()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: AppText.style(
        12,
        weight: FontWeight.w700,
        color: AppColors.chalkDim,
      ).copyWith(letterSpacing: 0.8),
    ),
  );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: v == selected,
          onSelected: (_) => onSelected(v),
        ),
    ],
  );
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppText.style(16, color: AppColors.tapeYellow)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: AppColors.chalkDim),
      ],
    ),
    onTap: onTap,
  );
}
