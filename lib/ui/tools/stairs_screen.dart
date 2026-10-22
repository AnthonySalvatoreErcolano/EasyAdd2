import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/quantity.dart';
import '../../engine/rational.dart';
import '../../engine/segment.dart';
import '../../engine/token.dart';
import '../../engine/tools/stairs.dart';
import '../../state/settings_controller.dart';
import '../../state/tool_forms.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'tool_widgets.dart';

class StairsScreen extends ConsumerWidget {
  const StairsScreen({super.key});

  static const tool = ToolKind.stairs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(toolFormProvider(tool));
    final r = ref.watch(stairsResultProvider);
    final settings = ref.watch(settingsProvider);
    final options = settings.formatOptions;
    List<Segment> fmt(Quantity q) => Formatter.format(q, options).segments;
    List<Segment> times(int n, Quantity each) => [
      NumberSegment('$n'),
      const SpaceSegment(),
      const OperatorSegment(Op.multiply),
      const SpaceSegment(),
      ...fmt(each),
    ];
    String limit(Rational inches) =>
        Formatter.format(Quantity.inches(inches), options).text;

    return ToolScaffold(
      tool: tool,
      summaryLabel: r != null && r.warnings.isNotEmpty
          ? 'Risers · over code'
          : 'Risers',
      summary: r == null ? null : times(r.risers, r.riserHeight),
      title: 'Stairs',
      choices: ChoiceBar<String>(
        values: const [treadMode, runMode],
        selected: form.choices[stairModeChoice]!,
        label: (v) => v == treadMode ? 'By tread depth' : 'By total run',
        onSelected: (v) => ref
            .read(toolFormProvider(tool).notifier)
            .setChoice(stairModeChoice, v),
      ),
      result: ResultCard(
        ready: r != null,
        placeholder: 'Enter the total rise, floor to floor.',
        headlineLabel: 'Risers',
        headline: r == null ? null : times(r.risers, r.riserHeight),
        rows: r == null
            ? const []
            : [
                if (r.treadDepth case final tread?)
                  ResultRow('Treads', times(r.treads, tread))
                else
                  const ResultRow('Treads', [NumberSegment('0')]),
                ResultRow('Total run', fmt(r.totalRun)),
                ResultRow('Diagonal', fmt(r.diagonal)),
                if (r.angleDegrees case final angle?)
                  ResultRow('Angle', [
                    NumberSegment('${angle.toStringAsFixed(1)}°'),
                  ]),
              ],
        footer: r == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final w in r.warnings)
                    _Warning(switch (w) {
                      StairWarning.riserTooTall =>
                        'Risers are taller than the '
                            '${limit(settings.codeMaxRiser)} code limit.',
                      StairWarning.treadTooShallow =>
                        'Treads are shallower than the '
                            '${limit(settings.codeMinTread)} code minimum.',
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      painter: StairProfilePainter(
                        risers: r.risers,
                        riserHeight: r.riserHeight.value.toDouble(),
                        tread: r.treadDepth?.value.toDouble() ?? 0,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.studRed,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.style(
              14,
              weight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A side view of the stair, to scale: each riser and tread, with the
/// diagonal dashed.
class StairProfilePainter extends CustomPainter {
  const StairProfilePainter({
    required this.risers,
    required this.riserHeight,
    required this.tread,
  });

  /// More steps than this are drawn as this many, to stay legible.
  static const maxDrawn = 24;

  final int risers;
  final double riserHeight;
  final double tread;

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.min(risers, maxDrawn);
    final rise = n * riserHeight;
    // Show a short landing at the top so a single step still reads.
    final step = tread > 0 ? tread : riserHeight;
    final run = (n - 1) * tread + step;
    final scale = math.min(size.width / run, size.height / rise);
    final dx = (size.width - run * scale) / 2;
    final bottom = size.height - (size.height - rise * scale) / 2;

    Offset at(double x, double y) => Offset(dx + x * scale, bottom - y * scale);

    final path = Path()..moveTo(at(0, 0).dx, at(0, 0).dy);
    var x = 0.0;
    var y = 0.0;
    for (var i = 0; i < n; i++) {
      y += riserHeight;
      path.lineTo(at(x, y).dx, at(x, y).dy);
      x += i < n - 1 ? tread : step;
      path.lineTo(at(x, y).dx, at(x, y).dy);
    }
    path
      ..lineTo(at(x, 0).dx, at(x, 0).dy)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.inkBlack);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.inkBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // The diagonal from the bottom nosing to the top floor.
    final from = at(0, 0);
    final to = at((n - 1) * tread, rise);
    final dash = Paint()
      ..color = AppColors.studRed
      ..strokeWidth = 2;
    const dashLength = 6.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    for (var d = 0.0; d < total; d += dashLength * 2) {
      canvas.drawLine(
        from + dir * d,
        from + dir * math.min(d + dashLength, total),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(StairProfilePainter old) =>
      old.risers != risers ||
      old.riserHeight != riserHeight ||
      old.tread != tread;
}
