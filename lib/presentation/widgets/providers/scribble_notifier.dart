import 'package:flutter/material.dart';
import 'package:lineleap/presentation/pages/scribble/scribble_page.dart';

// Enhanced ScribbleNotifier
class EnhancedScribbleNotifier extends ChangeNotifier {
  DrawingState _state = const DrawingState();
  DrawingState get state => _state;

  bool get canUndo => _state.historyIndex > 0;
  bool get canRedo => _state.historyIndex < _state.history.length - 1;

  void selectColor(Color color) {
    _state = _state.copyWith(selectedColor: color);
    notifyListeners();
  }

  void selectBrushStyle(BrushStyle style) {
    _state = _state.copyWith(brushStyle: style);
    notifyListeners();
  }

  void startStroke(Offset point) {
    final newStroke = Stroke(
      points: [point],
      color: _state.selectedColor,
      width: _state.brushStyle.width,
      style: _state.brushStyle,
    );

    final newStrokes = [..._state.strokes, newStroke];
    _saveToHistory(newStrokes);
  }

  void appendPoint(Offset point) {
    if (_state.strokes.isEmpty) return;

    final lastStroke = _state.strokes.last;
    final updatedStroke = lastStroke.copyWith(
      points: [...lastStroke.points, point],
    );

    final newStrokes = [
      ..._state.strokes.take(_state.strokes.length - 1),
      updatedStroke,
    ];

    _state = _state.copyWith(strokes: newStrokes);
    notifyListeners();
  }

  void endStroke() {
    // Stroke is already saved in history from startStroke
  }

  void undo() {
    if (!canUndo) return;

    final newIndex = _state.historyIndex - 1;
    _state = _state.copyWith(
      strokes: _state.history[newIndex],
      historyIndex: newIndex,
    );
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;

    final newIndex = _state.historyIndex + 1;
    _state = _state.copyWith(
      strokes: _state.history[newIndex],
      historyIndex: newIndex,
    );
    notifyListeners();
  }

  void clear() {
    _saveToHistory([]);
  }

  void _saveToHistory(List<Stroke> strokes) {
    final newHistory = _state.history.take(_state.historyIndex + 1).toList();
    newHistory.add(strokes);

    _state = _state.copyWith(
      strokes: strokes,
      history: newHistory,
      historyIndex: newHistory.length - 1,
    );
    notifyListeners();
  }
}

//
// Enhanced Stroke Model
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
