import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/tools/concrete.dart';
import 'package:easyadd/engine/units.dart';
import 'package:flutter_test/flutter_test.dart';

String cuFt(Quantity q) => Formatter.format(q).text;

String cuYd(Quantity q) => Formatter.format(
  q,
  const FormatOptions(volumeUnit: VolumeUnit.cubicYards),
).text;

List<int> bags(ConcreteResult r) => [for (final (_, n) in r.bagCounts) n];

ConcreteInput slab(int l, int w, int d, {int count = 1, int waste = 0}) =>
    ConcreteInput.slab(
      length: Rational(l),
      width: Rational(w),
      depth: Rational(d),
      count: count,
      wastePercent: Rational(waste),
    );

void main() {
  test('10\' × 12\' slab, 4" deep, no waste (scaffold table)', () {
    final r = Concrete.calculate(slab(120, 144, 4));
    expect(cuFt(r.volume), '40 cu ft');
    expect(cuYd(r.volume), '≈ 1.48 cu yd');
    expect(bags(r), [89, 67]); // 60 lb, 80 lb
  });

  test('same slab with 10% waste (scaffold table)', () {
    final r = Concrete.calculate(slab(120, 144, 4, waste: 10));
    expect(cuFt(r.volume), '40 cu ft');
    expect(cuFt(r.volumeWithWaste), '44 cu ft');
    expect(cuYd(r.volumeWithWaste), '≈ 1.63 cu yd');
    expect(bags(r), [98, 74]);
  });

  test('an exact multiple of a bag yield needs no extra bag', () {
    final r = Concrete.calculate(slab(36, 36, 4)); // 3 cu ft
    expect(cuFt(r.volume), '3 cu ft');
    expect(bags(r), [7, 5]);
  });

  test('count multiplies identical pours', () {
    final r = Concrete.calculate(slab(24, 24, 12, count: 4)); // 4 × 4 cu ft
    expect(cuFt(r.volume), '16 cu ft');
    expect(bags(r).last, 27);
  });

  test('round column: 12" diameter × 4\' high is π cu ft', () {
    final r = Concrete.calculate(
      ConcreteInput.column(diameter: Rational(12), height: Rational(48)),
    );
    expect(cuFt(r.volume), '≈ 3.14 cu ft');
    expect(cuYd(r.volume), '≈ 0.12 cu yd');
    expect(bags(r), [7, 6]);
    expect(r.volume.isVolume, isTrue);
  });

  test('custom bag sizes', () {
    final r = Concrete.calculate(
      ConcreteInput.slab(
        length: Rational(120),
        width: Rational(144),
        depth: Rational(4),
        bags: const [BagSize(50, 3, 8)], // 0.375 cu ft
      ),
    );
    expect(r.bagCounts.single.$1.pounds, 50);
    expect(bags(r), [107]); // 40 / 0.375 = 106.7
  });

  test('waste defaults to zero', () {
    final input = ConcreteInput.column(
      diameter: Rational(1),
      height: Rational(1),
    );
    expect(input.wastePercent, Rational.zero);
  });

  group('rejects', () {
    test('a zero or negative dimension', () {
      expect(() => Concrete.calculate(slab(120, 144, 0)), throwsArgumentError);
      expect(
        () => Concrete.calculate(
          ConcreteInput.column(diameter: Rational(-1), height: Rational(4)),
        ),
        throwsArgumentError,
      );
    });

    test('a count below one', () {
      expect(
        () => Concrete.calculate(slab(1, 1, 1, count: 0)),
        throwsArgumentError,
      );
    });

    test('negative waste', () {
      expect(
        () => Concrete.calculate(slab(1, 1, 1, waste: -5)),
        throwsArgumentError,
      );
    });
  });
}
