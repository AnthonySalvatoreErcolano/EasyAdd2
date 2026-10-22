import 'token.dart';

/// One piece of displayed text. The UI renders each kind differently, for
/// example a [FractionSegment] as a stacked fraction.
sealed class Segment {
  const Segment();

  /// The plain-text form, used for copying and in tests.
  String get text;
}

/// Digits, possibly with a decimal point, thousands commas or a leading −.
final class NumberSegment extends Segment {
  const NumberSegment(this.text);

  @override
  final String text;
}

final class FractionSegment extends Segment {
  const FractionSegment(this.numerator, this.denominator);

  final int numerator;
  final int denominator;

  @override
  String get text => '$numerator/$denominator';
}

enum MarkKind { feet, inches, unit }

/// A unit after a number: the feet mark ', the inch mark ", or a word such
/// as "mm" or "sq ft".
final class MarkSegment extends Segment {
  const MarkSegment(this.text, this.kind);

  const MarkSegment.feet() : this("'", MarkKind.feet);

  const MarkSegment.inches() : this('"', MarkKind.inches);

  const MarkSegment.unit(String label) : this(label, MarkKind.unit);

  @override
  final String text;
  final MarkKind kind;
}

final class SpaceSegment extends Segment {
  const SpaceSegment();

  @override
  String get text => ' ';
}

final class OperatorSegment extends Segment {
  const OperatorSegment(this.op);

  final Op op;

  @override
  String get text => op.symbol;
}

/// Shown before a result that was rounded for display.
final class ApproxSegment extends Segment {
  const ApproxSegment();

  @override
  String get text => '≈';
}

final class ErrorSegment extends Segment {
  const ErrorSegment();

  @override
  String get text => 'Error';
}

String segmentsText(Iterable<Segment> segments) =>
    segments.map((s) => s.text).join();
