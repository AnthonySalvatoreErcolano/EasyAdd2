import 'package:flutter/widgets.dart';

import '../../engine/segment.dart';
import '../theme/colors.dart';
import '../speech.dart';
import 'stacked_fraction.dart';

/// Renders display segments on one line: stacked fractions, prime marks
/// (′ ″), small unit words, and a red feet mark like a tape's foot marker.
/// Shrinks to fit its width and never wraps.
class MeasurementText extends StatelessWidget {
  const MeasurementText(
    this.segments, {
    super.key,
    required this.style,
    this.alignment = Alignment.centerRight,
    this.feetColor = AppColors.studRedOnBlade,
    this.dimColor,
  });

  final List<Segment> segments;
  final TextStyle style;
  final Alignment alignment;

  /// Color of the feet mark and of `Error`. The default reads on the
  /// yellow blade; dark surfaces pass a lighter color.
  final Color feetColor;

  /// Color for ≈ and operators. Defaults to the text color.
  final Color? dimColor;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 14;
    final dim = dimColor ?? style.color;
    final spans = <InlineSpan>[
      for (final segment in segments)
        switch (segment) {
          NumberSegment(:final text) => TextSpan(text: text),
          FractionSegment(:final numerator, :final denominator) => WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: StackedFraction(
              numerator: numerator,
              denominator: denominator,
              style: style,
            ),
          ),
          MarkSegment(kind: MarkKind.feet) => TextSpan(
            text: '′', // ′
            style: TextStyle(color: feetColor),
          ),
          MarkSegment(kind: MarkKind.inches) => const TextSpan(
            text: '″', // ″
          ),
          MarkSegment(:final text) => TextSpan(
            text: text,
            style: TextStyle(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          SpaceSegment() => TextSpan(
            text: ' ',
            style: TextStyle(fontSize: size * 0.7),
          ),
          OperatorSegment(:final text) ||
          EqualsSegment(:final text) => TextSpan(
            text: text,
            style: TextStyle(color: dim, fontWeight: FontWeight.w400),
          ),
          ApproxSegment(:final text) => TextSpan(
            text: text,
            style: TextStyle(
              color: dim,
              fontSize: size * 0.75,
              fontWeight: FontWeight.w400,
            ),
          ),
          ErrorSegment(:final text) => TextSpan(
            text: text,
            style: TextStyle(color: feetColor),
          ),
        },
    ];
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text.rich(
        TextSpan(
          style: style,
          children: spans.isEmpty ? [const TextSpan(text: ' ')] : spans,
        ),
        maxLines: 1,
        softWrap: false,
        semanticsLabel: spokenText(segments),
      ),
    );
  }
}
