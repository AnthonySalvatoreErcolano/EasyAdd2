@Tags(['golden'])
library;

import 'package:easyadd/state/tool_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../engine/helpers.dart';
import '../state/helpers.dart';
import 'ui_helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  void fill(ProviderContainer c, ToolKind tool, ToolField field, String input) {
    final form = c.read(toolFormProvider(tool).notifier)
      ..select(field)
      ..clearField();
    keys(input).forEach(form.input);
  }

  Future<ProviderContainer> openTool(WidgetTester t, String card) async {
    final c = await pumpApp(t);
    await t.tap(find.text('Tools'));
    await t.pumpAndSettle();
    if (card.isNotEmpty) {
      await t.tap(find.text(card));
      await t.pumpAndSettle();
    }
    return c;
  }

  Future<void> snap(WidgetTester t, String name) async {
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('tools list', (t) async {
    await openTool(t, '');
    await snap(t, 'tools_list_se');
  });

  testWidgets('concrete, empty', (t) async {
    await openTool(t, 'Concrete');
    await snap(t, 'tool_concrete_empty_se');
  });

  testWidgets('concrete, filled', (t) async {
    final c = await openTool(t, 'Concrete');
    fill(c, ToolKind.concrete, ToolFields.length, '10');
    fill(c, ToolKind.concrete, ToolFields.width, '12');
    fill(c, ToolKind.concrete, ToolFields.depth, '4');
    await snap(t, 'tool_concrete_se');
  });

  testWidgets('concrete, done typing', (t) async {
    final c = await openTool(t, 'Concrete');
    fill(c, ToolKind.concrete, ToolFields.length, '10');
    fill(c, ToolKind.concrete, ToolFields.width, '12');
    fill(c, ToolKind.concrete, ToolFields.depth, '4');
    c.read(toolFormProvider(ToolKind.concrete).notifier).done();
    await snap(t, 'tool_concrete_done_se');
  });

  testWidgets('stairs, done typing', (t) async {
    final c = await openTool(t, 'Stairs');
    fill(c, ToolKind.stairs, ToolFields.rise, '8\' 10"');
    c.read(toolFormProvider(ToolKind.stairs).notifier).done();
    await snap(t, 'tool_stairs_done_se');
  });

  testWidgets('stairs', (t) async {
    final c = await openTool(t, 'Stairs');
    fill(c, ToolKind.stairs, ToolFields.rise, '8\' 10"');
    await snap(t, 'tool_stairs_se');
  });

  testWidgets('stairs with a warning', (t) async {
    final c = await openTool(t, 'Stairs');
    fill(c, ToolKind.stairs, ToolFields.rise, '3\'');
    fill(c, ToolKind.stairs, ToolFields.tread, '9');
    await snap(t, 'tool_stairs_warning_se');
  });

  testWidgets('board feet', (t) async {
    final c = await openTool(t, 'Board Feet');
    fill(c, ToolKind.boardFeet, ToolFields.quantity, '10');
    fill(c, ToolKind.boardFeet, ToolFields.price, '1.25');
    await snap(t, 'tool_board_feet_se');
  });

  testWidgets('convert', (t) async {
    final c = await openTool(t, 'Convert');
    fill(c, ToolKind.convert, ToolFields.value, '1\' 2 1/2"');
    await snap(t, 'tool_convert_se');
  });

  testWidgets('settings sheet', (t) async {
    await pumpApp(t);
    await t.tap(find.byTooltip('Settings'));
    await snap(t, 'sheet_settings_se');
  });

  testWidgets('history sheet', (t) async {
    final c = await pumpApp(t);
    press(c, '2\' + 3" = = 5\' ÷ 7 = 10\' × 12\' =');
    await t.pump();
    await t.tap(find.byTooltip('History'));
    await snap(t, 'sheet_history_se');
  });
}
