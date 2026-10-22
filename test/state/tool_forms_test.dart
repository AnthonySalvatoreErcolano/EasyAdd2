import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/tools/board_feet.dart';
import 'package:easyadd/engine/tools/concrete.dart';
import 'package:easyadd/engine/tools/stairs.dart';
import 'package:easyadd/state/settings_controller.dart';
import 'package:easyadd/state/tool_forms.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../engine/helpers.dart';
import 'helpers.dart';

void main() {
  late ProviderContainer c;

  setUp(() async {
    (c, _) = await makeContainer();
  });

  ToolFormController form(ToolKind tool) =>
      c.read(toolFormProvider(tool).notifier);

  /// Selects [field] and replaces its contents with typed [input].
  void fill(ToolKind tool, ToolField field, String input) {
    form(tool)
      ..select(field)
      ..clearField();
    for (final t in keys(input)) {
      form(tool).input(t);
    }
  }

  String fmt(Quantity q) => Formatter.format(q).text;

  group('concrete', () {
    test('needs every size before showing a result', () {
      expect(c.read(concreteResultProvider), isNull);
      fill(ToolKind.concrete, ToolFields.length, '10');
      fill(ToolKind.concrete, ToolFields.width, '12');
      expect(c.read(concreteResultProvider), isNull);
    });

    test('a plain length is feet and a plain depth is inches', () {
      fill(ToolKind.concrete, ToolFields.length, '10');
      fill(ToolKind.concrete, ToolFields.width, '12');
      fill(ToolKind.concrete, ToolFields.depth, '4');
      fill(ToolKind.concrete, ToolFields.waste, '0');
      final r = c.read(concreteResultProvider)!;
      expect(fmt(r.volume), '40 cu ft');
      expect([for (final (_, n) in r.bagCounts) n], [89, 67]);
    });

    test('defaults to 10% waste and 1 pour', () {
      fill(ToolKind.concrete, ToolFields.length, '10');
      fill(ToolKind.concrete, ToolFields.width, '12');
      fill(ToolKind.concrete, ToolFields.depth, '4');
      expect(fmt(c.read(concreteResultProvider)!.volumeWithWaste), '44 cu ft');
    });

    test('fields accept tape measurements and arithmetic', () {
      fill(ToolKind.concrete, ToolFields.length, '9\' + 12"');
      fill(ToolKind.concrete, ToolFields.width, '12\' 0"');
      fill(ToolKind.concrete, ToolFields.depth, '4"');
      expect(fmt(c.read(concreteResultProvider)!.volume), '40 cu ft');
    });

    test('switching to a column shows diameter and height', () {
      form(ToolKind.concrete).setChoice(shapeChoice, ConcreteShape.column.name);
      final state = c.read(toolFormProvider(ToolKind.concrete));
      expect(state.fields.map((f) => f.id), [
        'diameter',
        'height',
        'count',
        'waste',
      ]);
      expect(state.active, 'diameter');
      fill(ToolKind.concrete, ToolFields.diameter, '12');
      fill(ToolKind.concrete, ToolFields.height, '4');
      fill(ToolKind.concrete, ToolFields.waste, '0');
      expect(fmt(c.read(concreteResultProvider)!.volume), '≈ 3.14 cu ft');
    });

    test('a count that is not a whole number gives no result', () {
      fill(ToolKind.concrete, ToolFields.length, '10');
      fill(ToolKind.concrete, ToolFields.width, '12');
      fill(ToolKind.concrete, ToolFields.depth, '4');
      fill(ToolKind.concrete, ToolFields.count, '1.5');
      expect(c.read(concreteResultProvider), isNull);
    });

    test('bag sizes come from settings', () {
      c
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(bags: const [BagSize(40, 3, 10)]));
      fill(ToolKind.concrete, ToolFields.length, '3');
      fill(ToolKind.concrete, ToolFields.width, '3');
      fill(ToolKind.concrete, ToolFields.depth, '4');
      fill(ToolKind.concrete, ToolFields.waste, '0');
      final bags = c.read(concreteResultProvider)!.bagCounts;
      expect(bags.single.$1.pounds, 40);
      expect(bags.single.$2, 10); // 3 cu ft ÷ 0.3
    });

    test('a zero size gives no result', () {
      fill(ToolKind.concrete, ToolFields.length, '0');
      fill(ToolKind.concrete, ToolFields.width, '12');
      fill(ToolKind.concrete, ToolFields.depth, '4');
      expect(c.read(concreteResultProvider), isNull);
    });
  });

  group('stairs', () {
    test('rise 8\' 10" with the default 7 3/4" riser and 10" tread', () {
      fill(ToolKind.stairs, ToolFields.rise, '8\' 10"');
      final r = c.read(stairsResultProvider)!;
      expect(r.risers, 14);
      expect(fmt(r.totalRun), '10\' 10"');
    });

    test('by total run', () {
      form(ToolKind.stairs).setChoice(stairModeChoice, runMode);
      fill(ToolKind.stairs, ToolFields.rise, '106');
      expect(c.read(stairsResultProvider), isNull);
      fill(ToolKind.stairs, ToolFields.run, '130');
      expect(fmt(c.read(stairsResultProvider)!.treadDepth!), '10"');
    });

    test('code limits come from settings', () {
      c
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(codeMinTread: Rational(11)));
      fill(ToolKind.stairs, ToolFields.rise, '106');
      expect(c.read(stairsResultProvider)!.warnings, {
        StairWarning.treadTooShallow,
      });
    });

    test('an empty max riser gives no result', () {
      fill(ToolKind.stairs, ToolFields.rise, '106');
      fill(ToolKind.stairs, ToolFields.maxRiser, '');
      expect(c.read(stairsResultProvider), isNull);
    });

    test('a total run for a single step gives no result', () {
      form(ToolKind.stairs).setChoice(stairModeChoice, runMode);
      fill(ToolKind.stairs, ToolFields.rise, '6');
      fill(ToolKind.stairs, ToolFields.run, '10');
      expect(c.read(stairsResultProvider), isNull);
    });
  });

  group('board feet', () {
    test('starts as one 2×6 × 8\'', () {
      final r = c.read(boardFeetResultProvider)!;
      expect(r.boardFeetEach, Rational(8));
      expect(r.totalPrice, isNull);
    });

    test('quantity and price', () {
      fill(ToolKind.boardFeet, ToolFields.quantity, '10');
      fill(ToolKind.boardFeet, ToolFields.price, '1.25');
      expect(
        Formatter.money(c.read(boardFeetResultProvider)!.totalPrice!),
        '\$100.00',
      );
    });

    test('sizing starts from settings and can be switched', () async {
      final (c2, _) = await makeContainer();
      c2
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(lumberSizing: LumberSizing.actual));
      expect(c2.read(boardFeetResultProvider)!.boardFeetEach, Rational(11, 2));
      c2
          .read(toolFormProvider(ToolKind.boardFeet).notifier)
          .setChoice(sizingChoice, LumberSizing.nominal.name);
      expect(c2.read(boardFeetResultProvider)!.boardFeetEach, Rational(8));
    });

    test('an empty size gives no result', () {
      fill(ToolKind.boardFeet, ToolFields.boardWidth, '');
      expect(c.read(boardFeetResultProvider), isNull);
    });

    test('a negative price gives no result', () {
      fill(ToolKind.boardFeet, ToolFields.price, '0 − 1');
      expect(c.read(boardFeetResultProvider), isNull);
    });
  });

  group('convert', () {
    test('turns any typed length into inches', () {
      expect(c.read(convertValueProvider), isNull);
      fill(ToolKind.convert, ToolFields.value, '1000 mm');
      expect(fmt(c.read(convertValueProvider)!), '≈ 3\' 3 3/8"');
    });

    test('a field with no answer is empty', () {
      fill(ToolKind.convert, ToolFields.value, '2 ÷ 0');
      expect(c.read(convertValueProvider), isNull);
    });

    test('an area is not a length', () {
      fill(ToolKind.convert, ToolFields.value, '2\' × 2\'');
      expect(c.read(convertValueProvider), isNull);
    });
  });

  group('form editing', () {
    test('typing goes into the selected field', () {
      final f = form(ToolKind.boardFeet);
      f.select(ToolFields.boardLength);
      f.input(const DigitToken(2));
      final state = c.read(toolFormProvider(ToolKind.boardFeet));
      expect(state.active, 'boardLength');
      expect(state.inches(ToolFields.boardLength), Rational(82 * 12));
    });

    test('backspace, clear, and operator replacement', () {
      final f = form(ToolKind.convert);
      for (final t in keys('5 +')) {
        f.input(t);
      }
      expect(f.canPress(const OpToken(Op.multiply)), isTrue);
      f.input(const OpToken(Op.multiply));
      final tokens = c
          .read(toolFormProvider(ToolKind.convert))
          .tokensOf(ToolFields.value);
      expect((tokens.last as OpToken).op, Op.multiply);
      f.backspace();
      f.backspace();
      f.backspace();
      f.backspace(); // already empty
      expect(
        c.read(toolFormProvider(ToolKind.convert)).tokensOf(ToolFields.value),
        isEmpty,
      );
      expect(f.canPress(const OpToken(Op.add)), isFalse);
    });

    test('keys that do not fit are ignored', () {
      final f = form(ToolKind.convert);
      f.input(const OpToken(Op.add));
      expect(
        c.read(toolFormProvider(ToolKind.convert)).tokensOf(ToolFields.value),
        isEmpty,
      );
    });

    test('changing a choice keeps the selected field when still shown', () {
      final f = form(ToolKind.stairs);
      f.select(ToolFields.rise);
      f.setChoice(stairModeChoice, runMode);
      expect(c.read(toolFormProvider(ToolKind.stairs)).active, 'rise');
    });

    test('reset puts every field back', () {
      fill(ToolKind.boardFeet, ToolFields.thickness, '4');
      form(ToolKind.boardFeet).reset();
      final state = c.read(toolFormProvider(ToolKind.boardFeet));
      expect(state.inches(ToolFields.thickness), Rational(2));
      expect(state.active, 'thickness');
    });

    test('number and count reject lengths', () {
      fill(ToolKind.concrete, ToolFields.count, '2\'');
      final state = c.read(toolFormProvider(ToolKind.concrete));
      expect(state.number(ToolFields.count), isNull);
      expect(state.count(ToolFields.count), isNull);
    });
  });
}
