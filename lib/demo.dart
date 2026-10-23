import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'engine/token.dart';
import 'engine/units.dart';
import 'state/calc_controller.dart';
import 'state/tool_forms.dart';
import 'ui/home_shell.dart';
import 'ui/sheets/history_sheet.dart';
import 'ui/tools/board_feet_screen.dart';
import 'ui/tools/concrete_screen.dart';
import 'ui/tools/stairs_screen.dart';

/// Screenshot mode works only in debug builds. Release (App Store) builds
/// compile it out, because [kDebugMode] is a constant false there.
const demoBuild = kDebugMode;

/// The scene to show. The screenshot script writes its name to
/// `easyadd_demo_scene` in the app's temporary folder before each launch.
String? demoScene() {
  if (!demoBuild) return null;
  final file = File('${Directory.systemTemp.path}/easyadd_demo_scene');
  if (!file.existsSync()) return null;
  final scene = file.readAsStringSync().trim();
  return scene.isEmpty ? null : scene;
}

/// Sets up [scene] once the first frame is on screen.
void runDemoScene(String scene, ProviderContainer c) {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Let the launch animation settle.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final calc = c.read(calcProvider.notifier);
    final shell = HomeShell.globalKey.currentState;

    void fill(ToolKind tool, ToolField field, String input) {
      final form = c.read(toolFormProvider(tool).notifier)
        ..select(field)
        ..clearField();
      _keys(input).forEach(form.input);
    }

    switch (scene) {
      case 'calculator':
        _press(calc, '1\' 2 1/2" + 3 7/8" =');
      case 'live-answer':
        _press(calc, '12\' 7 13/16" + 8\' 11 5/8');
      case 'concrete':
        fill(ToolKind.concrete, ToolFields.length, '24');
        fill(ToolKind.concrete, ToolFields.width, '16');
        fill(ToolKind.concrete, ToolFields.depth, '4');
        c.read(toolFormProvider(ToolKind.concrete).notifier).done();
        shell?.openTool(const ConcreteScreen());
      case 'stairs':
        fill(ToolKind.stairs, ToolFields.rise, '8\' 10"');
        c.read(toolFormProvider(ToolKind.stairs).notifier).done();
        shell?.openTool(const StairsScreen());
      case 'board-feet':
        fill(ToolKind.boardFeet, ToolFields.quantity, '24');
        fill(ToolKind.boardFeet, ToolFields.price, '1.35');
        c.read(toolFormProvider(ToolKind.boardFeet).notifier).done();
        shell?.openTool(const BoardFeetScreen());
      case 'history':
        _press(calc, '8\' ÷ 3 = 10\' × 12\' = 5\' ÷ 7 = 2\' + 3" = =');
        // Phones open the history sheet; iPads already show history.
        final context = HomeShell.globalKey.currentContext;
        if (context != null &&
            context.mounted &&
            MediaQuery.sizeOf(context).shortestSide < 600) {
          await showHistorySheet(context);
        }
    }
  });
}

void _press(CalcController calc, String input) {
  for (final word in input.split(' ')) {
    if (word == '=') {
      calc.equals();
      continue;
    }
    for (final token in _keys(word)) {
      switch (token) {
        case DigitToken(:final digit):
          calc.pressDigit(digit);
        case DecimalPointToken():
          calc.pressDecimal();
        case FractionToken(:final numerator, :final denominator):
          calc.pressFraction(numerator, denominator);
        case UnitToken(:final unit):
          calc.pressUnit(unit);
        case OpToken(:final op):
          calc.pressOp(op);
        case ValueToken():
          break;
      }
    }
  }
}

/// Key presses for readable input such as `1' 2 1/2" + 3`.
List<Token> _keys(String input) {
  final tokens = <Token>[];
  for (final word in input.split(' ').where((w) => w.isNotEmpty)) {
    final op = switch (word) {
      '+' => Op.add,
      '−' => Op.subtract,
      '×' => Op.multiply,
      '÷' => Op.divide,
      _ => null,
    };
    if (op != null) {
      tokens.add(OpToken(op));
      continue;
    }
    var body = word;
    Unit? unit;
    if (body.endsWith("'")) {
      unit = Unit.feet;
      body = body.substring(0, body.length - 1);
    } else if (body.endsWith('"')) {
      unit = Unit.inches;
      body = body.substring(0, body.length - 1);
    }
    if (body.contains('/')) {
      final parts = body.split('/');
      tokens.add(FractionToken(int.parse(parts[0]), int.parse(parts[1])));
    } else {
      for (final ch in body.split('')) {
        tokens.add(
          ch == '.' ? const DecimalPointToken() : DigitToken(int.parse(ch)),
        );
      }
    }
    if (unit != null) tokens.add(UnitToken(unit));
  }
  return tokens;
}
