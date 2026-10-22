import 'package:flutter/material.dart';

import '../../engine/token.dart';
import '../../engine/units.dart';
import '../theme/colors.dart';

/// The metric units offered by holding the `in` key.
Future<Unit?> showMetricMenu(
  BuildContext keyContext,
  bool Function(Token token) canPress,
) {
  final box = keyContext.findRenderObject()! as RenderBox;
  final overlay =
      Overlay.of(keyContext).context.findRenderObject()! as RenderBox;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
  final position = RelativeRect.fromRect(
    topLeft & box.size,
    Offset.zero & overlay.size,
  );
  return showMenu<Unit>(
    context: keyContext,
    position: position,
    color: AppColors.utilitySteel,
    items: [
      for (final unit in const [
        Unit.millimeters,
        Unit.centimeters,
        Unit.meters,
      ])
        PopupMenuItem(
          value: unit,
          enabled: canPress(UnitToken(unit)),
          child: Text(
            unit.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.chalkWhite,
            ),
          ),
        ),
    ],
  );
}
