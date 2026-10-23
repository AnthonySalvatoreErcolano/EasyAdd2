import 'package:flutter/rendering.dart';

import '../theme/colors.dart';

/// Tape-measure graduations along the top edge of the blade: 1/16" ticks
/// of five lengths, inch numbers, and a red "1F" box at 12" like a real
/// tape's foot marker.
class TapeTicksPainter extends CustomPainter {
  const TapeTicksPainter({this.pixelsPerInch = 28, this.shift = 0});

  final double pixelsPerInch;

  /// How far the tape has been pulled out, in pixels.
  final double shift;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final ink = Paint()
      ..color = AppColors.inkBlack
      ..strokeCap = StrokeCap.butt;
    final step = pixelsPerInch / 16;
    // Only the ticks on screen: from the first one past the left edge.
    final first = (shift / step).floor().clamp(1, 1 << 30);
    final last = ((size.width + shift) / step).ceil();

    for (var i = first; i <= last; i++) {
      final x = i * step - shift;
      if (x < 0) continue;
      final (length, width) = switch (i) {
        _ when i % 16 == 0 => (h * 0.62, 1.4),
        _ when i % 8 == 0 => (h * 0.46, 1.2),
        _ when i % 4 == 0 => (h * 0.33, 1.0),
        _ when i % 2 == 0 => (h * 0.24, 1.0),
        _ => (h * 0.15, 0.9),
      };
      ink.strokeWidth = width;
      canvas.drawLine(Offset(x, 0), Offset(x, length), ink);

      if (i % 16 == 0) _inchNumber(canvas, i ~/ 16, x, h);
    }
  }

  void _inchNumber(Canvas canvas, int inch, double x, double h) {
    final isFoot = inch % 12 == 0;
    final painter = TextPainter(
      text: TextSpan(
        text: isFoot ? '${inch ~/ 12}F' : '$inch',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: h * 0.36,
          fontWeight: FontWeight.w700,
          color: isFoot ? AppColors.chalkWhite : AppColors.inkBlack,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final origin = Offset(x + 3, h * 0.66 - painter.height);
    if (isFoot) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx - 2,
            origin.dy,
            painter.width + 4,
            painter.height,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.studRed,
      );
    }
    painter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(TapeTicksPainter old) =>
      old.pixelsPerInch != pixelsPerInch || old.shift != shift;
}
