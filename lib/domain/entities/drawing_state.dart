import 'package:flutter/material.dart';
import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

class DrawingState {
  final List<Stroke> strokes;
  final Color selectedColor;
  final BrushStyle brushStyle;
  final List<List<Stroke>> history;
  final int historyIndex;
  final MirrorMode mirrorMode;

  const DrawingState({
    this.strokes = const [],
    this.selectedColor = Colors.grey,
    this.brushStyle = BrushStyle.medium,
    this.history = const [],
    this.historyIndex = -1,
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
