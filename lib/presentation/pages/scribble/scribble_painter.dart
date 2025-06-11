import 'package:flutter/cupertino.dart';
import 'package:lineleap/presentation/pages/scribble/scribble_page.dart';
import 'package:lineleap/presentation/widgets/providers/scribble_notifier.dart';

class EnhancedScribblePainter extends CustomPainter {
  final List<Stroke> strokes;

  EnhancedScribblePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint =
          Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke; // Add this line

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
    return strokes != oldDelegate.strokes;
  }
}
