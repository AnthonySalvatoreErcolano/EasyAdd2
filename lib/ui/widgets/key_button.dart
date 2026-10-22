import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_controller.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

enum KeyKind { digit, fraction, unit, operator, utility, ghost }

/// One keypad key. Shrinks slightly and taps the haptic engine when
/// pressed; disabled keys are dimmed and ignore taps.
class KeyButton extends ConsumerStatefulWidget {
  const KeyButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.onLongPress,
    this.kind = KeyKind.digit,
    this.enabled = true,
    this.fontSize = 28,
  });

  final Widget label;
  final String semanticLabel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final KeyKind kind;
  final bool enabled;
  final double fontSize;

  @override
  ConsumerState<KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends ConsumerState<KeyButton> {
  bool _down = false;

  void _setDown(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _haptic() {
    if (ref.read(settingsProvider).haptics) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, bgDown, fg) = switch (widget.kind) {
      KeyKind.digit => (
        AppColors.keySteel,
        AppColors.keySteelPressed,
        AppColors.chalkWhite,
      ),
      KeyKind.fraction => (
        AppColors.keySteel,
        AppColors.keySteelPressed,
        AppColors.tapeYellow,
      ),
      KeyKind.unit => (
        AppColors.keySteel,
        AppColors.keySteelPressed,
        AppColors.chalkWhite,
      ),
      KeyKind.operator => (
        AppColors.tapeYellow,
        AppColors.bladeShadow,
        AppColors.inkBlack,
      ),
      KeyKind.utility => (
        AppColors.utilitySteel,
        AppColors.utilitySteelPressed,
        AppColors.chalkWhite,
      ),
      KeyKind.ghost => (
        const Color(0x00000000),
        AppColors.keySteel,
        AppColors.chalkDim,
      ),
    };
    final enabled = widget.enabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: enabled ? widget.onPressed : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setDown(true) : null,
        onTapUp: enabled ? (_) => _setDown(false) : null,
        onTapCancel: () => _setDown(false),
        onTap: enabled
            ? () {
                _haptic();
                widget.onPressed();
              }
            : null,
        onLongPress: enabled && widget.onLongPress != null
            ? () {
                _setDown(false);
                _haptic();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            decoration: BoxDecoration(
              color: _down ? bgDown : bg,
              borderRadius: BorderRadius.circular(14),
              border: widget.kind == KeyKind.fraction
                  ? Border.all(
                      color: AppColors.tapeYellow.withValues(
                        alpha: enabled ? 0.55 : 0.2,
                      ),
                      width: 1.2,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            // A disabled key keeps its color; only its label fades.
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.3,
              duration: const Duration(milliseconds: 120),
              child: DefaultTextStyle(
                style: AppText.style(
                  widget.fontSize,
                  weight: widget.kind == KeyKind.operator
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: fg,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: widget.label,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
