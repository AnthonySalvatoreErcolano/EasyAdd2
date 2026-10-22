import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/tools/board_feet.dart';
import 'package:flutter_test/flutter_test.dart';

BoardResult boards(
  int thickness,
  int width,
  int lengthFeet, {
  int quantity = 1,
  Rational? price,
  LumberSizing sizing = LumberSizing.nominal,
}) => BoardFeet.calculate(
  BoardInput(
    thickness: Rational(thickness),
    width: Rational(width),
    length: Rational(lengthFeet * 12),
    quantity: quantity,
    pricePerBoardFoot: price,
    sizing: sizing,
  ),
);

void main() {
  test('2×6 × 8\', qty 10 (scaffold table)', () {
    final r = boards(2, 6, 8, quantity: 10);
    expect(r.boardFeetEach, Rational(8));
    expect(r.totalBoardFeet, Rational(80));
    expect(r.totalPrice, isNull);
  });

  test('same at \$1.25 per board foot (scaffold table)', () {
    final r = boards(2, 6, 8, quantity: 10, price: Rational(5, 4));
    expect(Formatter.money(r.totalPrice!), '\$100.00');
  });

  test('1×4 × 10\' (scaffold table)', () {
    final r = boards(1, 4, 10);
    expect(Formatter.decimalText(r.totalBoardFeet, 2), ('3.33', true));
  });

  test('actual sizes give fewer board feet', () {
    final r = boards(2, 6, 8, sizing: LumberSizing.actual);
    expect(r.boardFeetEach, Rational(11, 2)); // 1.5 × 5.5 × 96 / 144
  });

  test('actual size of nominal lumber', () {
    expect(BoardFeet.actualSize(Rational(1)), Rational(3, 4));
    expect(BoardFeet.actualSize(Rational(2)), Rational(3, 2));
    expect(BoardFeet.actualSize(Rational(6)), Rational(11, 2));
    expect(BoardFeet.actualSize(Rational(8)), Rational(29, 4));
    expect(BoardFeet.actualSize(Rational(12)), Rational(45, 4));
    expect(BoardFeet.actualSize(Rational(5, 2)), Rational(5, 2));
  });

  group('rejects', () {
    test('a quantity below one', () {
      expect(() => boards(2, 6, 8, quantity: 0), throwsArgumentError);
    });

    test('a size that is not positive', () {
      expect(() => boards(2, 0, 8), throwsArgumentError);
      expect(() => boards(2, 6, 0), throwsArgumentError);
    });

    test('a negative price', () {
      expect(() => boards(2, 6, 8, price: Rational(-1)), throwsArgumentError);
    });
  });

  test('money formatting', () {
    expect(Formatter.money(Rational(246900, 200)), '\$1,234.50');
    expect(Formatter.money(Rational(1, 8)), '\$0.13');
    expect(Formatter.money(Rational(-5)), '−\$5.00');
  });
}
