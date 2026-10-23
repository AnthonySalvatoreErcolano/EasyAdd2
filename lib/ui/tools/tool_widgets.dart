import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/entry_builder.dart';
import '../../engine/segment.dart';
import '../../engine/token.dart';
import '../../engine/units.dart';
import '../../state/tool_forms.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/fraction_strip.dart';
import '../widgets/key_button.dart';
import '../widgets/measurement_text.dart';
import '../widgets/unit_menu.dart';

/// A tool screen: choices at the top, input fields, a live result card, and
/// a compact tape-measure keypad pinned to the bottom.
class ToolScaffold extends ConsumerWidget {
  const ToolScaffold({
    super.key,
    required this.tool,
    required this.title,
    required this.result,
    required this.summaryLabel,
    required this.summary,
    this.choices,
  });

  final ToolKind tool;
  final String title;
  final Widget result;

  /// The main answer, pinned above the keypad while typing so it stays in
  /// view on small phones. Null until the inputs are complete.
  final String summaryLabel;
  final List<Segment>? summary;
  final Widget? choices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(toolFormProvider(tool));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Start over',
            icon: const Icon(Icons.restart_alt),
            onPressed: ref.read(toolFormProvider(tool).notifier).reset,
          ),
        ],
      ),
      body: ReadableWidth(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (choices != null) ...[
                    choices!,
                    const SizedBox(height: 12),
                  ],
                  for (final field in form.fields) ...[
                    FieldRow(tool: tool, field: field),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  result,
                ],
              ),
            ),
            // The keypad is a fixed layout, so its text grows only a little.
            if (form.editing)
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  children: [
                    _SummaryBar(label: summaryLabel, value: summary),
                    ToolKeypad(tool: tool),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keeps content to a comfortable reading width on iPad, centered.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  static const maxWidth = 640.0;

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.label, required this.value});

  final String label;
  final List<Segment>? value;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    color: AppColors.tapeYellow,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Text(
          label,
          style: AppText.style(
            14,
            weight: FontWeight.w600,
            color: AppColors.inkDim,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: value == null
              ? Text(
                  '—',
                  textAlign: TextAlign.right,
                  style: AppText.style(22, color: AppColors.inkDim),
                )
              : MeasurementText(
                  value!,
                  style: AppText.style(
                    26,
                    weight: FontWeight.w700,
                    color: AppColors.inkBlack,
                  ),
                  dimColor: AppColors.inkDim,
                ),
        ),
      ],
    ),
  );
}

/// One input: its label on the left, the typed value on the right. Tap to
/// type into it; the selected field has a yellow outline.
class FieldRow extends ConsumerWidget {
  const FieldRow({super.key, required this.tool, required this.field});

  final ToolKind tool;
  final ToolField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(toolFormProvider(tool));
    final active = form.active == field.id;
    final tokens = form.tokensOf(field);

    // Scroll a newly selected field into view above the keypad.
    ref.listen(toolFormProvider(tool).select((f) => f.active), (_, next) {
      if (next != field.id) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
    });
    final segments = EntryBuilder.parse(tokens).segments;
    final hint = field.kind == FieldKind.length ? field.defaultUnit.label : '';

    return Semantics(
      button: true,
      selected: active,
      label: '${field.label}, ${segmentsText(segments)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => ref.read(toolFormProvider(tool).notifier).select(field),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.keySteel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.tapeYellow : Colors.transparent,
              width: 2,
            ),
          ),
          child: LabelValueRow(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: field.label),
                  if (hint.isNotEmpty)
                    TextSpan(
                      text: '  $hint',
                      style: AppText.style(13, color: AppColors.chalkDim),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(16, color: AppColors.chalkWhite),
            ),
            value: Row(
              children: [
                Expanded(
                  child: tokens.isEmpty
                      ? Text(
                          active ? '' : '—',
                          textAlign: TextAlign.right,
                          style: AppText.style(20, color: AppColors.chalkDim),
                        )
                      : MeasurementText(
                          segments,
                          style: AppText.style(
                            22,
                            weight: FontWeight.w600,
                            color: AppColors.chalkWhite,
                          ),
                          dimColor: AppColors.chalkDim,
                          feetColor: AppColors.tapeYellow,
                        ),
                ),
                if (active)
                  Container(
                    width: 2,
                    height: 26,
                    margin: const EdgeInsets.only(left: 3),
                    color: AppColors.tapeYellow,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The keypad for tool fields:
///
///     fractions …          16ths
///     7  8  9  ⌫
///     4  5  6  ft
///     1  2  3  in
///     .  0  +  Next
///
/// Hold ⌫ to clear the field; hold `in` for metric.
class ToolKeypad extends ConsumerWidget {
  const ToolKeypad({super.key, required this.tool});

  final ToolKind tool;

  static const _gap = 6.0;
  static const _keyHeight = 46.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onLast = ref.watch(toolFormProvider(tool)).onLastField;
    final form = ref.read(toolFormProvider(tool).notifier);
    final isLength = form.activeField.kind == FieldKind.length;
    bool can(Token t) => form.canPress(t);

    Widget digit(int d) => KeyButton(
      label: Text('$d'),
      semanticLabel: '$d',
      fontSize: 24,
      enabled: can(DigitToken(d)),
      onPressed: () => form.input(DigitToken(d)),
    );

    final rows = <List<Widget>>[
      [
        digit(7),
        digit(8),
        digit(9),
        KeyButton(
          kind: KeyKind.utility,
          label: const Text('⌫'),
          semanticLabel: 'Delete. Hold to clear the field',
          fontSize: 22,
          onPressed: form.backspace,
          onLongPress: form.clearField,
        ),
      ],
      [
        digit(4),
        digit(5),
        digit(6),
        KeyButton(
          kind: KeyKind.unit,
          label: const Text('ft'),
          semanticLabel: 'Feet',
          fontSize: 20,
          enabled: isLength && can(const UnitToken(Unit.feet)),
          onPressed: () => form.input(const UnitToken(Unit.feet)),
        ),
      ],
      [
        digit(1),
        digit(2),
        digit(3),
        Builder(
          builder: (keyContext) => KeyButton(
            kind: KeyKind.unit,
            label: const Text('in'),
            semanticLabel: 'Inches. Hold for metric units',
            fontSize: 20,
            enabled:
                isLength &&
                (can(const UnitToken(Unit.inches)) ||
                    can(const UnitToken(Unit.millimeters))),
            onPressed: () => form.input(const UnitToken(Unit.inches)),
            onLongPress: () async {
              final unit = await showMetricMenu(keyContext, can);
              if (unit != null) form.input(UnitToken(unit));
            },
          ),
        ),
      ],
      [
        KeyButton(
          label: const Text('.'),
          semanticLabel: 'Decimal point',
          fontSize: 26,
          enabled: can(const DecimalPointToken()),
          onPressed: () => form.input(const DecimalPointToken()),
        ),
        digit(0),
        KeyButton(
          kind: KeyKind.utility,
          label: const Text('+'),
          semanticLabel: 'Plus',
          fontSize: 26,
          enabled: can(const OpToken(Op.add)),
          onPressed: () => form.input(const OpToken(Op.add)),
        ),
        KeyButton(
          kind: KeyKind.operator,
          label: Text(onLast ? 'Done' : 'Next'),
          semanticLabel: onLast ? 'Done. Hide the keypad' : 'Next field',
          fontSize: 18,
          onPressed: form.selectNext,
        ),
      ],
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF17191B),
        border: Border(top: BorderSide(color: AppColors.keySteel)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: FractionStrip(
                gap: _gap,
                onFraction: (n, d) => form.input(FractionToken(n, d)),
                canPress: (t) => isLength && can(t),
              ),
            ),
            for (final row in rows) ...[
              const SizedBox(height: _gap),
              SizedBox(
                height: _keyHeight,
                child: Row(
                  children: [
                    for (var k = 0; k < row.length; k++) ...[
                      if (k > 0) const SizedBox(width: _gap),
                      Expanded(child: row[k]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The yellow card that shows a tool's answer. Shows [placeholder] until
/// the inputs are complete.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.ready,
    this.headlineLabel,
    this.headline,
    this.rows = const [],
    this.footer,
    this.placeholder = 'Fill in the sizes above.',
  });

  final bool ready;
  final String? headlineLabel;
  final List<Segment>? headline;
  final List<ResultRow> rows;
  final Widget? footer;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.tapeYellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: !ready
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                placeholder,
                style: AppText.style(16, color: AppColors.inkDim),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (headline != null) ...[
                  if (headlineLabel != null)
                    Text(
                      headlineLabel!,
                      style: AppText.style(
                        13,
                        weight: FontWeight.w600,
                        color: AppColors.inkDim,
                      ),
                    ),
                  SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(52),
                    child: MeasurementText(
                      headline!,
                      alignment: Alignment.centerLeft,
                      style: AppText.style(
                        42,
                        weight: FontWeight.w700,
                        color: AppColors.inkBlack,
                      ),
                      dimColor: AppColors.inkDim,
                    ),
                  ),
                  if (rows.isNotEmpty)
                    const Divider(height: 18, color: Color(0x33000000)),
                ],
                for (final row in rows) row,
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ),
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow(this.label, this.value, {super.key});

  final String label;
  final List<Segment> value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: LabelValueRow(
      label: Text(
        label,
        maxLines: 2,
        style: AppText.style(15, color: AppColors.inkDim),
      ),
      value: SizedBox(
        height: MediaQuery.textScalerOf(context).scale(26),
        child: MeasurementText(
          value,
          style: AppText.style(
            20,
            weight: FontWeight.w700,
            color: AppColors.inkBlack,
          ),
          dimColor: AppColors.inkDim,
        ),
      ),
    ),
  );
}

/// A label on the left and a value filling the rest of the row, right
/// aligned. The label takes what it needs, up to 60% of the row, and wraps
/// beyond that (large text sizes).
class LabelValueRow extends StatelessWidget {
  const LabelValueRow({super.key, required this.label, required this.value});

  final Widget label;
  final Widget value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
          child: label,
        ),
        const SizedBox(width: 12),
        Expanded(child: value),
      ],
    ),
  );
}

/// A row of mutually exclusive options, such as Slab / Round column.
class ChoiceBar<T> extends StatelessWidget {
  const ChoiceBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) =>
      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: _buttons());

  Widget _buttons() => SegmentedButton<T>(
    showSelectedIcon: false,
    expandedInsets: EdgeInsets.zero,
    segments: [
      for (final v in values) ButtonSegment(value: v, label: Text(label(v))),
    ],
    selected: {selected},
    onSelectionChanged: (s) => onSelected(s.first),
  );
}
