import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/segment.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

String fmt(Quantity q, [FormatOptions options = const FormatOptions()]) =>
    Formatter.format(q, options).text;

Quantity inches(int n, [int d = 1]) => Quantity.inches(Rational(n, d));

void main() {
  group('feet and inches', () {
    test('typical values', () {
      expect(fmt(inches(81, 2)), '3\' 4 1/2"');
      expect(fmt(inches(15, 2)), '7 1/2"');
      expect(fmt(inches(36)), '3\' 0"');
      expect(fmt(inches(1, 2)), '1/2"');
      expect(fmt(inches(0)), '0"');
      expect(fmt(inches(25, 2)), '1\' 1/2"');
    });

    test('negative values carry one minus sign', () {
      expect(fmt(inches(-15)), '−1\' 3"');
      expect(fmt(inches(-3, 8)), '−3/8"');
    });

    test('rounding carries into the next inch and foot', () {
      expect(fmt(inches(383, 32)), '≈ 1\' 0"'); // 11 31/32"
      expect(fmt(inches(63, 32)), '≈ 2"'); // 1 31/32"
    });

    test('tiny negative values round to zero without a sign', () {
      expect(fmt(inches(-1, 64)), '≈ 0"');
    });

    test('precision setting', () {
      const eighths = FormatOptions(precision: 8);
      const thirtySeconds = FormatOptions(precision: 32);
      expect(fmt(inches(60, 7), eighths), '≈ 8 5/8"');
      expect(fmt(inches(60, 7), thirtySeconds), '≈ 8 9/16"');
      expect(fmt(inches(1, 32), thirtySeconds), '1/32"');
    });

    test('segments mark the feet and inch symbols and the fraction', () {
      final segments = Formatter.format(inches(41, 2)).segments;
      expect(segments.whereType<FractionSegment>().single.text, '1/2');
      expect(segments.whereType<MarkSegment>().map((m) => m.kind), [
        MarkKind.feet,
        MarkKind.inches,
      ]);
      expect(Formatter.format(inches(41, 2)).approximate, isFalse);
    });
  });

  group('other length displays', () {
    test('inches only', () {
      const options = FormatOptions(lengthDisplay: LengthDisplay.inches);
      expect(fmt(inches(81, 2), options), '40 1/2"');
    });

    test('decimal feet', () {
      const options = FormatOptions(lengthDisplay: LengthDisplay.decimalFeet);
      expect(fmt(inches(81, 2), options), '3.375\'');
      expect(fmt(inches(40), options), '≈ 3.3333\'');
    });

    test('metric', () {
      expect(
        fmt(
          inches(10),
          const FormatOptions(lengthDisplay: LengthDisplay.millimeters),
        ),
        '254 mm',
      );
      expect(
        fmt(
          inches(10),
          const FormatOptions(lengthDisplay: LengthDisplay.centimeters),
        ),
        '25.4 cm',
      );
      expect(
        fmt(
          inches(100),
          const FormatOptions(lengthDisplay: LengthDisplay.meters),
        ),
        '2.54 m',
      );
      expect(
        fmt(
          inches(1200),
          const FormatOptions(lengthDisplay: LengthDisplay.millimeters),
        ),
        '30,480 mm',
      );
    });
  });

  group('areas and volumes', () {
    final area = Quantity(Rational(144 * 120), 2); // 120 sq ft
    final volume = Quantity(Rational(1728 * 6), 3); // 6 cu ft

    test('area units', () {
      expect(fmt(area), '120 sq ft');
      expect(
        fmt(area, const FormatOptions(areaUnit: AreaUnit.squareInches)),
        '17,280 sq in',
      );
      expect(
        fmt(area, const FormatOptions(areaUnit: AreaUnit.squareYards)),
        '≈ 13.33 sq yd',
      );
      expect(
        fmt(area, const FormatOptions(areaUnit: AreaUnit.squareMeters)),
        '≈ 11.15 m²',
      );
    });

    test('volume units', () {
      expect(fmt(volume), '6 cu ft');
      expect(
        fmt(volume, const FormatOptions(volumeUnit: VolumeUnit.cubicInches)),
        '10,368 cu in',
      );
      expect(
        fmt(volume, const FormatOptions(volumeUnit: VolumeUnit.cubicMeters)),
        '≈ 0.17 m³',
      );
    });
  });

  group('plain numbers', () {
    test('trims trailing zeros and rounds to 6 places', () {
      expect(fmt(Quantity.number(Rational(5, 2))), '2.5');
      expect(fmt(Quantity.number(Rational(8, 3))), '≈ 2.666667');
      expect(fmt(Quantity.number(Rational(-1234567))), '−1,234,567');
    });

    test('decimalText reports rounding', () {
      expect(Formatter.decimalText(Rational(1, 8), 3), ('0.125', false));
      expect(Formatter.decimalText(Rational(1, 8), 2), ('0.13', true));
      expect(Formatter.decimalText(Rational(-1, 1000), 2), ('0', true));
    });
  });

  test('error text', () {
    expect(Formatter.error.text, 'Error');
  });

  test('copyWith replaces only the given options', () {
    const base = FormatOptions();
    final changed = base.copyWith(precision: 8);
    expect(changed.precision, 8);
    expect(changed.lengthDisplay, base.lengthDisplay);
    final all = base.copyWith(
      lengthDisplay: LengthDisplay.meters,
      areaUnit: AreaUnit.squareMeters,
      volumeUnit: VolumeUnit.cubicMeters,
    );
    expect(all.precision, 16);
    expect(all.areaUnit, AreaUnit.squareMeters);
    expect(all.volumeUnit, VolumeUnit.cubicMeters);
    expect(all.lengthDisplay, LengthDisplay.meters);
  });

  test('every segment kind has plain text', () {
    expect(
      segmentsText(const [
        ApproxSegment(),
        SpaceSegment(),
        NumberSegment('3'),
        MarkSegment.feet(),
        SpaceSegment(),
        FractionSegment(5, 8),
        MarkSegment.inches(),
        SpaceSegment(),
        MarkSegment.unit('mm'),
        SpaceSegment(),
        EqualsSegment(),
        ErrorSegment(),
      ]),
      '≈ 3\' 5/8" mm =Error',
    );
  });
}
