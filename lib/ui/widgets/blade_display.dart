import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/formatter.dart';
import '../../engine/quantity.dart';
import '../../engine/segment.dart';
import '../../engine/units.dart';
import '../../state/calc_controller.dart';
import '../../state/settings.dart';
import '../../state/settings_controller.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'measurement_text.dart';
import 'tape_ticks.dart';

/// The yellow tape blade: graduations along the top, the expression, the
/// result (or a live preview), and the exact decimal inches.
///
/// Tap the result to change its units; hold it to copy.
class BladeDisplay extends ConsumerWidget {
  const BladeDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calc = ref.watch(calcProvider);
    final settings = ref.watch(settingsProvider);
    final options = settings.formatOptions;
    final display = calc.display(options);
    final value = calc.currentValue;
    final memory = calc.memory;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final reduceMotion = MediaQuery.of(context).disableAnimations;
        final resultSize = (h * 0.34).clamp(40.0, 84.0);
        final expressionSize = (h * 0.1).clamp(18.0, 26.0);
        final tickHeight = (h * 0.19).clamp(22.0, 34.0);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.tapeYellow,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: tickHeight, child: const _ExtendingTape()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (memory != null) _MemoryBadge(memory, options),
                            Expanded(
                              child: MeasurementText(
                                display.expression,
                                style: AppText.style(
                                  expressionSize,
                                  color: AppColors.inkDim,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: value == null
                                ? null
                                : () => _cycleUnits(ref, value, settings),
                            onLongPress: display.result == null
                                ? null
                                : () => _copy(context, display.result!),
                            child: SizedBox(
                              height: resultSize * 1.2,
                              child: Semantics(
                                liveRegion: display.isFinal,
                                child: AnimatedSwitcher(
                                  duration: reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  switchInCurve: Curves.easeOutCubic,
                                  transitionBuilder: _slideUp,
                                  layoutBuilder: (current, previous) => Stack(
                                    alignment: Alignment.centerRight,
                                    children: [...previous, ?current],
                                  ),
                                  // Typing updates the preview in place; each
                                  // `=` slides a new result up into view.
                                  child: KeyedSubtree(
                                    key: ValueKey<Object>(
                                      display.isFinal
                                          ? identityHashCode(calc.evaluation)
                                          : 'preview',
                                    ),
                                    child: MeasurementText(
                                      display.result?.segments ??
                                          (calc.tokens.isEmpty
                                              ? const [NumberSegment('0')]
                                              : const []),
                                      style: AppText.style(
                                        display.isFinal
                                            ? resultSize
                                            : resultSize * 0.8,
                                        weight: FontWeight.w700,
                                        color: display.isFinal
                                            ? AppColors.inkBlack
                                            : AppColors.inkBlack.withValues(
                                                alpha: 0.6,
                                              ),
                                      ),
                                      dimColor: AppColors.inkDim,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 16,
                          child: Text(
                            _readout(value),
                            textAlign: TextAlign.right,
                            style: AppText.style(12.5, color: AppColors.inkDim),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _slideUp(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.35),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );

  /// The exact decimal inches under a length.
  static String _readout(Quantity? value) {
    if (value == null || !value.isLength) return '';
    final (text, approximate) = Formatter.decimalText(value.value, 4);
    return '${approximate ? '≈' : '='} $text in';
  }

  static void _cycleUnits(WidgetRef ref, Quantity value, Settings settings) {
    T next<T>(List<T> order, T current) =>
        order[(order.indexOf(current) + 1) % order.length];

    ref
        .read(settingsProvider.notifier)
        .update(
          (s) => switch (value.dimension) {
            1 => s.copyWith(
              lengthDisplay: next(LengthDisplay.values, s.lengthDisplay),
            ),
            2 => s.copyWith(
              areaUnit: next(const [
                AreaUnit.squareFeet,
                AreaUnit.squareYards,
                AreaUnit.squareMeters,
                AreaUnit.squareInches,
              ], s.areaUnit),
            ),
            3 => s.copyWith(
              volumeUnit: next(const [
                VolumeUnit.cubicFeet,
                VolumeUnit.cubicYards,
                VolumeUnit.cubicMeters,
                VolumeUnit.cubicInches,
              ], s.volumeUnit),
            ),
            _ => s,
          },
        );
  }

  static void _copy(BuildContext context, FormattedValue result) {
    final text = result.text.replaceFirst('≈ ', '');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied $text'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _MemoryBadge extends StatelessWidget {
  const _MemoryBadge(this.memory, this.options);

  final Quantity memory;
  final FormatOptions options;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memory holds ${Formatter.format(memory, options).text}',
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.inkBlack,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'M',
          style: AppText.style(
            12,
            weight: FontWeight.w700,
            color: AppColors.tapeYellow,
          ),
        ),
      ),
    );
  }
}

/// The tape graduations. Each result pulls the tape out 2 inches, like
/// extending a real tape; AC lets it retract.
class _ExtendingTape extends ConsumerStatefulWidget {
  const _ExtendingTape();

  static const pixelsPerInch = 28.0;

  @override
  ConsumerState<_ExtendingTape> createState() => _ExtendingTapeState();
}

class _ExtendingTapeState extends ConsumerState<_ExtendingTape> {
  double _pulled = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(calcProvider, (previous, next) {
      final newResult =
          next.evaluation != null &&
          !identical(next.evaluation, previous?.evaluation);
      final cleared =
          next.evaluation == null &&
          next.tokens.isEmpty &&
          (previous?.isEvaluated ?? false);
      if (newResult) {
        setState(() => _pulled += 2 * _ExtendingTape.pixelsPerInch);
      } else if (cleared) {
        setState(() => _pulled = 0);
      }
    });
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _pulled),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, shift, _) => CustomPaint(
        painter: TapeTicksPainter(
          pixelsPerInch: _ExtendingTape.pixelsPerInch,
          shift: shift,
        ),
      ),
    );
  }
}
