import 'dart:ui';

import 'package:lineleap/core/config/brush.dart';

class Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final BrushStyle style;

  const Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.style,
  });

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? width,
    BrushStyle? style,
  }) {
    return Stroke(
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }
}
