@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../state/helpers.dart';
import 'ui_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> shot(
    WidgetTester tester,
    String name,
    String keysToPress, {
    Size size = iPhoneSE,
  }) async {
    final container = await pumpApp(tester, size: size);
    press(container, keysToPress);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('empty', (t) => shot(t, 'calc_empty_se', ''));
  testWidgets(
    'typing with preview',
    (t) => shot(t, 'calc_typing_se', '1\' 2 1/2" + 3 7/8'),
  );
  testWidgets(
    'result',
    (t) => shot(t, 'calc_result_se', '1\' 2 1/2" + 3 7/8" ='),
  );
  testWidgets('rounded', (t) => shot(t, 'calc_rounded_se', '5\' ÷ 7 ='));
  testWidgets('negative', (t) => shot(t, 'calc_negative_se', '1\' − 2\' ='));
  testWidgets('carry', (t) => shot(t, 'calc_carry_se', '11 15/16" + 1/16" ='));
  testWidgets('area', (t) => shot(t, 'calc_area_se', '10\' × 12\' ='));
  testWidgets('error', (t) => shot(t, 'calc_error_se', '2" ÷ 0 ='));
  testWidgets(
    'long expression',
    (t) => shot(
      t,
      'calc_long_se',
      '12\' 7 13/16" + 8\' 11 5/8" − 3\' 4 1/4" × 2 + 6 15/16" =',
    ),
  );
  testWidgets(
    'memory',
    (t) => shot(t, 'calc_memory_se', '4\' 6" = M+ C 2\' ×'),
  );
  testWidgets(
    'large phone',
    (t) => shot(t, 'calc_result_69', '1\' 2 1/2" + 3 7/8" =', size: iPhone69),
  );
  testWidgets(
    'iPad with history',
    (t) => shot(t, 'calc_ipad', '2\' + 3" = = 8\' ÷ 3 =', size: iPadPro13),
  );
}
