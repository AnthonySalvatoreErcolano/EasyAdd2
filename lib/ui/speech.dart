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
