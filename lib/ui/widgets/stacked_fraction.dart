import 'package:flutter/widgets.dart';

import '../speech.dart';

/// A tape-measure fraction: a raised numerator, a slanted bar and a
/// denominator on the baseline, each about 60% of the surrounding size.
class StackedFraction extends StatelessWidget {
  const StackedFraction({
    super.key,
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  final int numerator;
  final int denominator;

  /// The style of the whole numbers around the fraction.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 14;
    final small = style.copyWith(
      fontSize: size * 0.6,
      height: 1,
      fontWeight: style.fontWeight == FontWeight.w400
          ? FontWeight.w500
          : style.fontWeight,
    );
    return Semantics(
      label: fractionWords(numerator, denominator),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size * 0.02),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Transform.translate(
              offset: Offset(0, -size * 0.32),
              child: Text('$numerator', style: small),
            ),
            Text(
              '⁄', // fraction slash
              style: small.copyWith(
                fontSize: size * 0.8,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text('$denominator', style: small),
          ],
        ),
      ),
    );
  }
}
