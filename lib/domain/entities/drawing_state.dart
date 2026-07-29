import 'dart:ui';

import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/config/mirror_mode.dart';
import 'package:lineleap/domain/entities/stroke.dart';

class DrawingState {
  final List<Stroke> strokes;
  final Color selectedColor;
  final BrushStyle brushStyle;
  final List<List<Stroke>> history;
  final int historyIndex;
  final MirrorMode mirrorMode;

  const DrawingState({
    this.strokes = const [],
    this.selectedColor = const Color(0xFF9E9E9E),
    this.brushStyle = BrushStyle.medium,
    this.history = const <List<Stroke>>[<Stroke>[]],
    this.historyIndex = 0,
    this.mirrorMode = MirrorMode.none,
  });

  DrawingState copyWith({
    List<Stroke>? strokes,
    Color? selectedColor,
    BrushStyle? brushStyle,
    List<List<Stroke>>? history,
    int? historyIndex,
    MirrorMode? mirrorMode,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      selectedColor: selectedColor ?? this.selectedColor,
      brushStyle: brushStyle ?? this.brushStyle,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      mirrorMode: mirrorMode ?? this.mirrorMode,
    );
  }
}
