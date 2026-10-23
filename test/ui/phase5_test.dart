import 'package:easyadd/engine/formatter.dart';
import 'package:easyadd/engine/segment.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/ui/speech.dart';
import 'package:easyadd/ui/widgets/tape_ticks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../engine/helpers.dart';
import '../state/helpers.dart';
import 'ui_helpers.dart';

String spokenResult(String input) {
  final result = evaluate(input)!;
  return spokenText(Formatter.format(result).segments);
}

double tapeShift(WidgetTester t) {
  final paint = t
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .firstWhere((p) => p.painter is TapeTicksPainter);
  return (paint.painter! as TapeTicksPainter).shift;
}

void main() {
  setUpAll(loadAppFonts);

  group('VoiceOver words', () {
    test('lengths', () {
      expect(spokenResult('3\' 4 5/8"'), '3 feet 4 and five eighths inches');
      expect(spokenResult('1\' 1"'), '1 foot 1 inch');
      expect(spokenResult('1/2"'), 'one half inch');
      expect(spokenResult('7 1/2"'), '7 and one half inches');
      expect(spokenResult('5\' ÷ 7'), 'about 8 and nine sixteenths inches');
      expect(spokenResult('1\' − 2\''), 'minus 1 foot 0 inches');
    });

    test('areas, volumes and numbers', () {
      expect(spokenResult('10\' × 12\''), '120 square feet');
      expect(spokenResult('3\' × 4\' × 6"'), '6 cubic feet');
      expect(spokenResult('1,000 + 234'.replaceAll(',', '')), '1234');
    });

    test('expressions, errors and units', () {
      expect(
        spokenText(const [
          NumberSegment('2'),
          SpaceSegment(),
          OperatorSegment(Op.divide),
          SpaceSegment(),
          NumberSegment('3'),
          SpaceSegment(),
          EqualsSegment(),
          SpaceSegment(),
          ErrorSegment(),
        ]),
        '2 divided by 3 equals error',
      );
      expect(
        spokenText(const [
          NumberSegment('368.3'),
          SpaceSegment(),
          MarkSegment.unit('mm'),
          NumberSegment('  ·  '),
          NumberSegment('80'),
          MarkSegment.unit('BF'),
          MarkSegment.unit('furlongs'),
        ]),
        '368.3 millimeters 80 board feet furlongs',
      );
    });
  });

  group('animations', () {
    testWidgets('each result pulls the tape out and AC retracts it', (t) async {
      final c = await pumpApp(t);
      expect(tapeShift(t), 0);
      press(c, '2 + 3 =');
      await t.pumpAndSettle();
      final once = tapeShift(t);
      expect(once, greaterThan(0));
      press(c, '=');
      await t.pumpAndSettle();
      expect(tapeShift(t), greaterThan(once));
      press(c, 'C');
      await t.pumpAndSettle();
      expect(tapeShift(t), 0);
    });

    testWidgets('the tape moves gradually', (t) async {
      final c = await pumpApp(t);
      press(c, '2 + 3 =');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      final midway = tapeShift(t);
      await t.pumpAndSettle();
      expect(midway, greaterThan(0));
      expect(midway, lessThan(tapeShift(t)));
    });

    testWidgets('Reduce Motion skips the animation', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final c = await pumpApp(t);
      press(c, '2 + 3 =');
      await t.pump();
      await t.pump();
      final shift = tapeShift(t);
      await t.pumpAndSettle();
      expect(shift, tapeShift(t));
    });
  });

  group('double text size has no cut-off layouts', () {
    Future<void> atDoubleText(WidgetTester t, String name) async {
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('calculator, tools and every tool screen', (t) async {
      await atDoubleText(t, 'calc');
      final c = await pumpApp(t);
      press(c, '12\' 7 13/16" + 8\' 11 5/8" =');
      await t.pumpAndSettle();
      await t.tap(find.text('Tools'));
      await t.pumpAndSettle();
      for (final tool in ['Concrete', 'Stairs', 'Board Feet', 'Convert']) {
        await t.scrollUntilVisible(find.text(tool), 100);
        await t.tap(find.text(tool));
        await t.pumpAndSettle();
        await t.tap(find.byTooltip('Back'));
        await t.pumpAndSettle();
      }
    });

    testWidgets('settings and history sheets', (t) async {
      await atDoubleText(t, 'sheets');
      final c = await pumpApp(t);
      press(c, '2\' + 3" = 5\' ÷ 7 =');
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView).last, const Offset(0, -2000));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(10, 10)); // close
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('History'));
      await t.pumpAndSettle();
    });
  });
}
