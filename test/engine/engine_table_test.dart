// The engine test table from scaffold.md. Every expected value was worked
// out by hand.
import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const cases = <(String, String, String)>[
    ('1\' 2 1/2" + 3 7/8"', '1\' 6 3/8"', 'mixed units, carry into feet'),
    ('5\' 3 1/4" − 2\' 7 3/4"', '2\' 7 1/2"', 'borrow across feet'),
    ('11 15/16" + 1/16"', '1\' 0"', 'exact carry to a foot'),
    ('3/8" + 1/8"', '1/2"', 'fraction reduction'),
    ('2\' 3" × 4', '9\' 0"', 'length × number'),
    ('6 3/4" × 2', '1\' 1 1/2"', 'fraction × number'),
    ('8\' ÷ 3', '2\' 8"', 'exact division'),
    ('5\' ÷ 7', '≈ 8 9/16"', 'rounding to 1/16 with the ≈ mark'),
    ('8\' ÷ 1\' 4"', '6', 'length ÷ length gives a count'),
    ('1\' − 2\'', '−1\' 0"', 'negative result'),
    ('2" + 3 × 4', '1\' 2"', 'precedence; bare number counts as inches'),
    ('2 + 3', '5', 'no units gives a plain number'),
    ('2 1/2" ÷ 0', 'Error', 'divide by zero'),
    ('10\' × 12\'', '120 sq ft', 'area'),
    ('12\' 6" × 10\' 3"', '≈ 128.13 sq ft', 'area rounded (exact 128.125)'),
    ('3\' × 4\' × 6"', '6 cu ft', 'volume'),
    ('1000 mm', '≈ 3\' 3 3/8"', 'metric entry shown in feet and inches'),
    ('1\' + 10 cm', '≈ 1\' 3 15/16"', 'mixed imperial and metric'),
    ('10\' × 12\' × 12\' × 1\'', 'Error', 'dimension overflow'),
  ];

  for (final (input, expected, what) in cases) {
    test('$input = $expected ($what)', () {
      expect(calc(input), expected);
    });
  }

  group('chains of operations', () {
    const chains = <(String, String)>[
      ('1\' + 2\' − 6"', '2\' 6"'),
      ('1 + 2 + 3 + 4', '10'),
      ('10\' − 2\' − 3\'', '5\' 0"'),
      ('2 × 3 + 4 × 5', '26'),
      ('1\' + 6" × 2 − 3"', '1\' 9"'),
      ('24 ÷ 2 ÷ 3', '4'),
      ('2\' × 3\' + 1\' × 4\'', '10 sq ft'),
    ];
    for (final (input, expected) in chains) {
      test('$input = $expected', () => expect(calc(input), expected));
    }
  });

  test('3\' × 4\' × 6" in cubic yards is ≈ 0.22 cu yd', () {
    expect(
      calc(
        '3\' × 4\' × 6"',
        const FormatOptions(volumeUnit: VolumeUnit.cubicYards),
      ),
      '≈ 0.22 cu yd',
    );
  });

  test('1\' 2 1/2" in millimeters is 368.3 mm', () {
    expect(
      calc(
        '1\' 2 1/2"',
        const FormatOptions(lengthDisplay: LengthDisplay.millimeters),
      ),
      '368.3 mm',
    );
  });
}
