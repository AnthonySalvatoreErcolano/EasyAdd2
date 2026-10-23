import 'package:easyadd/engine/segment.dart';
import 'package:easyadd/engine/units.dart';
import 'package:easyadd/state/calc_controller.dart';
import 'package:easyadd/state/settings_controller.dart';
import 'package:easyadd/state/tool_forms.dart';
import 'package:easyadd/ui/speech.dart';
import 'package:easyadd/ui/widgets/measurement_text.dart';
import 'package:easyadd/ui/widgets/stacked_fraction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_helpers.dart';

/// Taps keys by their VoiceOver labels.
Future<void> tapKeys(WidgetTester t, List<String> labels) async {
  for (final label in labels) {
    final finder = find.bySemanticsLabel(label);
    expect(finder, findsWidgets, reason: 'No key labeled "$label"');
    await t.tap(finder.last);
    await t.pump();
  }
  await t.pumpAndSettle();
}

String bladeResult(ProviderContainer c) {
  final options = c.read(settingsProvider).formatOptions;
  return c.read(calcProvider).display(options).result?.text ?? '';
}

void main() {
  setUpAll(loadAppFonts);

  group('calculator screen', () {
    testWidgets('tapping keys calculates 1\' 2 1/2" + 3 7/8"', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, [
        '1',
        'Feet',
        '2',
        'one half',
        'Inches. Hold for metric units',
        'Plus',
        '3',
        'seven eighths',
        'Equals',
      ]);
      expect(bladeResult(c), '1\' 6 3/8"');
      // The result is drawn with a stacked 3/8.
      expect(
        find.byWidgetPredicate(
          (w) => w is StackedFraction && w.numerator == 3 && w.denominator == 8,
        ),
        findsWidgets,
      );
    });

    testWidgets('sixteenths toggle shows the odd sixteenths', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, ['5', 'Show sixteenths', 'nine sixteenths']);
      expect(c.read(calcProvider).tokens, hasLength(2));
      // It switches back to eighths after one tap.
      expect(find.bySemanticsLabel('Show sixteenths'), findsOneWidget);
    });

    testWidgets('disabled keys do nothing', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, ['Plus']);
      expect(c.read(calcProvider).tokens, isEmpty);
    });

    testWidgets('tapping the result cycles length units', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, ['1', 'Feet', 'Equals']);
      await t.tap(find.text('= 12 in'));
      await t.pump();
      expect(c.read(settingsProvider).lengthDisplay, LengthDisplay.feetInches);
      // Tap the big result itself.
      await t.tap(find.byType(MeasurementText).at(1));
      await t.pumpAndSettle();
      expect(c.read(settingsProvider).lengthDisplay, LengthDisplay.inches);
      expect(bladeResult(c), '12"');
    });

    testWidgets('holding the result copies it', (t) async {
      String? copied;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      await pumpApp(t);
      await tapKeys(t, ['5', 'Feet', 'Divide', '7', 'Equals']);
      await t.longPress(find.byType(MeasurementText).at(1));
      await t.pumpAndSettle();
      expect(copied, '8 9/16"');
      expect(find.text('Copied 8 9/16"'), findsOneWidget);
    });

    testWidgets('history sheet puts a past result back', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, ['2', 'Plus', '3', 'Equals', 'All clear']);
      await t.tap(find.byTooltip('History'));
      await t.pumpAndSettle();
      await t.tap(find.text('2 + 3 ='));
      await t.pumpAndSettle();
      expect(c.read(calcProvider).currentValue?.value.toString(), '5');
    });

    testWidgets('settings sheet changes precision', (t) async {
      final c = await pumpApp(t);
      await t.tap(find.byTooltip('Settings'));
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('one eighth').last);
      await t.pumpAndSettle();
      expect(c.read(settingsProvider).precision, 8);
    });

    testWidgets('holding in offers metric units', (t) async {
      final c = await pumpApp(t);
      await tapKeys(t, ['2', '5', '4']);
      await t.longPress(find.bySemanticsLabel(RegExp('^Inches')).last);
      await t.pumpAndSettle();
      await t.tap(find.text('mm'));
      await t.pumpAndSettle();
      await tapKeys(t, ['Equals']);
      expect(bladeResult(c), '10"');
    });
  });

  group('tools', () {
    Future<ProviderContainer> openTool(WidgetTester t, String name) async {
      final c = await pumpApp(t);
      await t.tap(find.text('Tools'));
      await t.pumpAndSettle();
      await t.tap(find.text(name));
      await t.pumpAndSettle();
      return c;
    }

    testWidgets('concrete: type sizes with Next, then Done', (t) async {
      final c = await openTool(t, 'Concrete');
      await tapKeys(t, ['1', '0', 'Next field', '1', '2', 'Next field', '4']);
      expect(find.text('Concrete to order'), findsWidgets);
      expect(c.read(concreteResultProvider), isNotNull);
      await tapKeys(t, ['Next field', 'Next field', 'Done. Hide the keypad']);
      expect(c.read(toolFormProvider(ToolKind.concrete)).editing, isFalse);
      expect(find.text('Next'), findsNothing);
      // Tapping a field brings the keypad back.
      await t.tap(find.textContaining('Depth'));
      await t.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('a count field disables fractions and units', (t) async {
      final c = await openTool(t, 'Concrete');
      await tapKeys(t, ['Next field', 'Next field', 'Next field']);
      expect(c.read(toolFormProvider(ToolKind.concrete)).active, 'count');
      expect(find.text('How many'), findsOneWidget); // scrolled into view
      await tapKeys(t, ['one half', 'Feet']);
      expect(
        c.read(toolFormProvider(ToolKind.concrete)).tokensOf(ToolFields.count),
        hasLength(1),
      );
    });

    testWidgets('holding delete clears a field', (t) async {
      final c = await openTool(t, 'Board Feet');
      await t.longPress(find.bySemanticsLabel(RegExp('^Delete')).last);
      await t.pumpAndSettle();
      expect(
        c
            .read(toolFormProvider(ToolKind.boardFeet))
            .tokensOf(ToolFields.thickness),
        isEmpty,
      );
    });

    testWidgets('choices switch the fields', (t) async {
      await openTool(t, 'Concrete');
      await t.tap(find.text('Round column'));
      await t.pumpAndSettle();
      expect(find.textContaining('Diameter'), findsOneWidget);
      expect(find.textContaining('Width'), findsNothing);
    });

    testWidgets('start over resets the form', (t) async {
      final c = await openTool(t, 'Board Feet');
      await tapKeys(t, ['Delete. Hold to clear the field']);
      await t.tap(find.byTooltip('Start over'));
      await t.pumpAndSettle();
      expect(c.read(boardFeetResultProvider), isNotNull);
    });

    testWidgets('tapping Tools again returns to the list', (t) async {
      await openTool(t, 'Stairs');
      await t.tap(find.text('Tools').last);
      await t.pumpAndSettle();
      expect(find.text('Board Feet'), findsOneWidget);
    });
  });

  testWidgets('iPad keeps history beside the calculator', (t) async {
    await pumpApp(t, size: iPadPro13);
    expect(find.text('History'), findsOneWidget);
    expect(find.byTooltip('History'), findsNothing);
  });

  test('fraction words for VoiceOver', () {
    expect(fractionWords(1, 2), 'one half');
    expect(fractionWords(3, 8), 'three eighths');
    expect(fractionWords(15, 16), 'fifteen sixteenths');
    expect(fractionWords(1, 64), 'one sixty-fourth');
    expect(fractionWords(17, 32), '17 thirty-seconds');
    expect(fractionWords(1, 3), '1 over 3');
  });

  testWidgets('MeasurementText draws every segment kind', (t) async {
    await t.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MeasurementText([
          ApproxSegment(),
          NumberSegment('3'),
          MarkSegment.feet(),
          SpaceSegment(),
          FractionSegment(5, 8),
          MarkSegment.inches(),
          MarkSegment.unit('sq ft'),
          EqualsSegment(),
          ErrorSegment(),
        ], style: TextStyle(fontSize: 20)),
      ),
    );
    expect(find.byType(StackedFraction), findsOneWidget);
  });
}
