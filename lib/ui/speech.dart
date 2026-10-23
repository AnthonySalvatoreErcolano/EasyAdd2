import '../engine/segment.dart';
import '../engine/token.dart';

const _numbers = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
];

const _denominators = {
  2: ('half', 'halves'),
  4: ('quarter', 'quarters'),
  8: ('eighth', 'eighths'),
  16: ('sixteenth', 'sixteenths'),
  32: ('thirty-second', 'thirty-seconds'),
  64: ('sixty-fourth', 'sixty-fourths'),
};

/// How VoiceOver reads a fraction: 3/8 is "three eighths".
String fractionWords(int numerator, int denominator) {
  final count = numerator < _numbers.length
      ? _numbers[numerator]
      : '$numerator';
  final names = _denominators[denominator];
  if (names == null) return '$numerator over $denominator';
  return '$count ${numerator == 1 ? names.$1 : names.$2}';
}

const _unitWords = {
  'sq in': 'square inches',
  'sq ft': 'square feet',
  'sq yd': 'square yards',
  'm²': 'square meters',
  'cu in': 'cubic inches',
  'cu ft': 'cubic feet',
  'cu yd': 'cubic yards',
  'm³': 'cubic meters',
  'mm': 'millimeters',
  'cm': 'centimeters',
  'm': 'meters',
  'BF': 'board feet',
};

const _opWords = {
  Op.add: 'plus',
  Op.subtract: 'minus',
  Op.multiply: 'times',
  Op.divide: 'divided by',
};

/// How VoiceOver reads a measurement or expression, for example
/// `3' 4 5/8"` is "3 feet 4 and 5 eighths inches" and `≈ 8 9/16"` is
/// "about 8 and 9 sixteenths inches".
String spokenText(List<Segment> segments) {
  final words = <String>[];
  // The number before the current unit mark, to choose foot/feet.
  String? lastNumber;
  var sawFraction = false;

  for (final s in segments) {
    switch (s) {
      case NumberSegment(:final text) when text == '−':
        words.add('minus');
      case NumberSegment(:final text):
        final t = text.trim();
        if (t.isEmpty || t == '·') continue;
        final clean = t.replaceAll(',', '');
        words.add(clean);
        lastNumber = clean;
        sawFraction = false;
      case FractionSegment(:final numerator, :final denominator):
        if (lastNumber != null) words.add('and');
        words.add(fractionWords(numerator, denominator));
        sawFraction = true;
      case MarkSegment(kind: MarkKind.feet):
        words.add(lastNumber == '1' ? 'foot' : 'feet');
        lastNumber = null;
      case MarkSegment(kind: MarkKind.inches):
        final single =
            (lastNumber == '1' && !sawFraction) ||
            (lastNumber == null && sawFraction);
        words.add(single ? 'inch' : 'inches');
        lastNumber = null;
        sawFraction = false;
      case MarkSegment(:final text):
        words.add(_unitWords[text] ?? text);
        lastNumber = null;
      case OperatorSegment(:final op):
        words.add(_opWords[op]!);
        lastNumber = null;
        sawFraction = false;
      case EqualsSegment():
        words.add('equals');
      case ApproxSegment():
        words.add('about');
      case ErrorSegment():
        words.add('error');
      case SpaceSegment():
        break;
    }
  }
  return words.join(' ');
}
