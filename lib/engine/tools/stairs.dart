import 'dart:math' as math;

import '../quantity.dart';
import '../rational.dart';

enum StairWarning {
  /// Each riser is taller than the code limit.
  riserTooTall,

  /// Each tread is shallower than the code minimum.
  treadTooShallow,
}

/// Lengths are in inches. Give either [treadDepth] or [totalRun]; with
/// neither, the tread depth defaults to 10".
final class StairInput {
  StairInput({
    required this.totalRise,
    Rational? maxRiser,
    Rational? treadDepth,
    this.totalRun,
    Rational? codeMaxRiser,
    Rational? codeMinTread,
  }) : maxRiser = maxRiser ?? defaultMaxRiser,
       treadDepth = totalRun == null ? (treadDepth ?? defaultTread) : null,
       codeMaxRiser = codeMaxRiser ?? defaultMaxRiser,
       codeMinTread = codeMinTread ?? defaultTread;

  /// IRC R311.7.5 limits for residential stairs.
  static final Rational defaultMaxRiser = Rational(31, 4);
  static final Rational defaultTread = Rational(10);

  final Rational totalRise;
  final Rational maxRiser;
  final Rational? treadDepth;
  final Rational? totalRun;
  final Rational codeMaxRiser;
  final Rational codeMinTread;
}

final class StairResult {
  const StairResult({
    required this.risers,
    required this.riserHeight,
    required this.treads,
    required this.treadDepth,
    required this.totalRun,
    required this.diagonal,
    required this.angleDegrees,
    required this.warnings,
  });

  final int risers;
  final Quantity riserHeight;
  final int treads;

  /// Null for a single step, which has no treads.
  final Quantity? treadDepth;
  final Quantity totalRun;

  /// Straight-line length from the bottom of the first riser to the top of
  /// the last: √(rise² + run²). Rounded to a millionth of an inch.
  final Quantity diagonal;

  /// Steepness of the stair, from riser height over tread depth. Null for a
  /// single step.
  final double? angleDegrees;
  final Set<StairWarning> warnings;
}

abstract final class Stairs {
  /// Throws [ArgumentError] for a rise, riser limit, tread or run that is
  /// not positive, or a total run given for a single step.
  static StairResult calculate(StairInput input) {
    _positive(input.totalRise, 'totalRise');
    _positive(input.maxRiser, 'maxRiser');

    final risers = (input.totalRise / input.maxRiser).ceil().toInt();
    final riserHeight = input.totalRise / Rational(risers);
    final treads = risers - 1;

    Rational? tread;
    if (input.totalRun case final run?) {
      _positive(run, 'totalRun');
      if (treads == 0) {
        throw ArgumentError('A single step has no run to divide.');
      }
      tread = run / Rational(treads);
    } else if (treads > 0) {
      tread = _positive(input.treadDepth!, 'treadDepth');
    }
    final run = tread == null ? Rational.zero : tread * Rational(treads);

    final rise = input.totalRise.toDouble();
    final diagonal = math.sqrt(rise * rise + run.toDouble() * run.toDouble());

    return StairResult(
      risers: risers,
      riserHeight: Quantity.inches(riserHeight),
      treads: treads,
      treadDepth: tread == null ? null : Quantity.inches(tread),
      totalRun: Quantity.inches(run),
      diagonal: Quantity.inches(Rational.fromDouble(diagonal, places: 6)),
      angleDegrees: tread == null
          ? null
          : math.atan(riserHeight.toDouble() / tread.toDouble()) *
                180 /
                math.pi,
      warnings: {
        if (riserHeight > input.codeMaxRiser) StairWarning.riserTooTall,
        if (tread != null && tread < input.codeMinTread)
          StairWarning.treadTooShallow,
      },
    );
  }

  static Rational _positive(Rational value, String name) {
    if (value <= Rational.zero) throw ArgumentError.value(value, name);
    return value;
  }
}
