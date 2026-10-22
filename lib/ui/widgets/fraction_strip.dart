import 'package:flutter/material.dart';

import '../../engine/token.dart';
import '../speech.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'key_button.dart';
import 'stacked_fraction.dart';

const _eighths = [(1, 8), (1, 4), (3, 8), (1, 2), (5, 8), (3, 4), (7, 8)];
const _sixteenths = [
  (1, 16),
  (3, 16),
  (5, 16),
  (7, 16),
  (9, 16),
  (11, 16),
  (13, 16),
  (15, 16),
];

/// The row of fraction keys: eighths, plus a toggle that swaps in the odd
/// sixteenths for one tap.
class FractionStrip extends StatefulWidget {
  const FractionStrip({
    super.key,
    required this.onFraction,
    required this.canPress,
    this.gap = 6,
  });

  final void Function(int numerator, int denominator) onFraction;
  final bool Function(Token token) canPress;
  final double gap;

  @override
  State<FractionStrip> createState() => _FractionStripState();
}

class _FractionStripState extends State<FractionStrip> {
  bool _sixteenthsShown = false;

  @override
  Widget build(BuildContext context) {
    final fractions = _sixteenthsShown ? _sixteenths : _eighths;
    final keys = <Widget>[
      for (final (n, d) in fractions)
        KeyButton(
          kind: KeyKind.fraction,
          fontSize: 24,
          semanticLabel: fractionWords(n, d),
          enabled: widget.canPress(FractionToken(n, d)),
          onPressed: () {
            widget.onFraction(n, d);
            if (_sixteenthsShown) setState(() => _sixteenthsShown = false);
          },
          label: StackedFraction(
            numerator: n,
            denominator: d,
            style: AppText.style(
              24,
              weight: FontWeight.w600,
              color: AppColors.tapeYellow,
            ),
          ),
        ),
      KeyButton(
        kind: KeyKind.utility,
        fontSize: 15,
        semanticLabel: _sixteenthsShown ? 'Show eighths' : 'Show sixteenths',
        onPressed: () => setState(() => _sixteenthsShown = !_sixteenthsShown),
        label: Text(_sixteenthsShown ? '8ths' : '16ths'),
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) SizedBox(width: widget.gap),
          Expanded(child: keys[i]),
        ],
      ],
    );
  }
}
