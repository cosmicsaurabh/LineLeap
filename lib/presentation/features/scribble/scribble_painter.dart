import 'package:flutter/cupertino.dart';
import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

class EnhancedScribblePainter extends CustomPainter {
  final List<Stroke> strokes;
  final MirrorMode mirrorMode;
  final double canvasWidth;
  final double canvasHeight;

  EnhancedScribblePainter(
    this.strokes, {
    this.mirrorMode = MirrorMode.none,
    this.canvasWidth = 0,
    this.canvasHeight = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw mirror lines if mirror mode is active
    if (mirrorMode.isActive && canvasWidth > 0 && canvasHeight > 0) {
      final linePaint =
          Paint()
            ..color = const Color(
              0x80007AFF,
            ) // Semi-transparent blue (iOS primary color)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      const dashLength = 8.0;
      const dashSpace = 4.0;

      // Draw vertical mirror line (if vertical or both)
      if (mirrorMode.hasVertical) {
        final centerX = canvasWidth / 2;
        double currentY = 0;
        while (currentY < size.height) {
          canvas.drawLine(
            Offset(centerX, currentY),
            Offset(centerX, (currentY + dashLength).clamp(0.0, size.height)),
            linePaint,
          );
          currentY += dashLength + dashSpace;
        }
      }

      // Draw horizontal mirror line (if horizontal or both)
      if (mirrorMode.hasHorizontal) {
        final centerY = canvasHeight / 2;
        double currentX = 0;
        while (currentX < size.width) {
          canvas.drawLine(
            Offset(currentX, centerY),
            Offset((currentX + dashLength).clamp(0.0, size.width), centerY),
            linePaint,
          );
          currentX += dashLength + dashSpace;
        }
      }
    }

    // Draw all strokes
    for (final stroke in strokes) {
      final paint =
          Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

      if (stroke.style == BrushStyle.dotted) {
        _drawDottedStroke(canvas, stroke, paint);
      } else {
        _drawSmoothStroke(canvas, stroke, paint);
      }
    }
  }

  void _drawSmoothStroke(Canvas canvas, Stroke stroke, Paint paint) {
    if (stroke.points.length < 2) return;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final current = stroke.points[i];
      final next = stroke.points[i + 1];
      final controlPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(
        current.dx,
        current.dy,
        controlPoint.dx,
        controlPoint.dy,
      );
    }

    if (stroke.points.length > 1) {
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawDottedStroke(Canvas canvas, Stroke stroke, Paint paint) {
    for (int i = 0; i < stroke.points.length; i += 3) {
      canvas.drawCircle(stroke.points[i], stroke.width / 2, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedScribblePainter oldDelegate) {
    return strokes != oldDelegate.strokes ||
        mirrorMode != oldDelegate.mirrorMode ||
        canvasWidth != oldDelegate.canvasWidth ||
        canvasHeight != oldDelegate.canvasHeight;
  }
}
