import 'package:flutter/material.dart';
import 'package:lineleap/presentation/features/scribble/scribble_page.dart';

class EnhancedScribbleNotifier extends ChangeNotifier {
  DrawingState _state = const DrawingState();
  DrawingState get state => _state;
  
  // Track the index of the original stroke when in mirror mode
  // This helps us identify which stroke to mirror when appending points
  int? _mirrorPairStartIndex;

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

  void toggleMirrorMode() {
    _state = _state.copyWith(isMirrorMode: !_state.isMirrorMode);
    // Clear mirror pair tracking when toggling mirror mode
    _mirrorPairStartIndex = null;
    notifyListeners();
  }

  void startStroke(Offset point, {double? canvasWidth}) {
    final newStroke = Stroke(
      points: [point],
      color: _state.selectedColor,
      width: _state.brushStyle.width,
      style: _state.brushStyle,
    );

    List<Stroke> strokesToAdd = [newStroke];
    
    // If mirror mode is active and we have canvas width, create mirrored stroke
    if (_state.isMirrorMode && canvasWidth != null) {
      final centerX = canvasWidth / 2;
      final mirroredX = centerX * 2 - point.dx;
      final mirroredPoint = Offset(mirroredX, point.dy);
      
      final mirroredStroke = Stroke(
        points: [mirroredPoint],
        color: _state.selectedColor,
        width: _state.brushStyle.width,
        style: _state.brushStyle,
      );
      strokesToAdd.add(mirroredStroke);
      // Track the index of the original stroke (before adding the pair)
      _mirrorPairStartIndex = _state.strokes.length;
    } else {
      _mirrorPairStartIndex = null;
    }

    final newStrokes = [..._state.strokes, ...strokesToAdd];
    _saveToHistory(newStrokes);
  }

  void appendPoint(Offset point, {double? canvasWidth}) {
    if (_state.strokes.isEmpty) return;

    // In mirror mode, we have pairs of strokes (original + mirrored)
    // We need to update both the original stroke and its mirror
    if (_state.isMirrorMode && 
        canvasWidth != null && 
        _mirrorPairStartIndex != null &&
        _mirrorPairStartIndex! < _state.strokes.length - 1) {
      final centerX = canvasWidth / 2;
      final mirroredX = centerX * 2 - point.dx;
      final mirroredPoint = Offset(mirroredX, point.dy);
      
      // Update both the original stroke and its mirror
      final originalStroke = _state.strokes[_mirrorPairStartIndex!];
      final mirroredStroke = _state.strokes[_mirrorPairStartIndex! + 1];
      
      final updatedOriginalStroke = originalStroke.copyWith(
        points: [...originalStroke.points, point],
      );
      
      final updatedMirroredStroke = mirroredStroke.copyWith(
        points: [...mirroredStroke.points, mirroredPoint],
      );

      final newStrokes = List<Stroke>.from(_state.strokes);
      newStrokes[_mirrorPairStartIndex!] = updatedOriginalStroke;
      newStrokes[_mirrorPairStartIndex! + 1] = updatedMirroredStroke;

      _state = _state.copyWith(strokes: newStrokes);
      notifyListeners();
    } else {
      // Normal mode - just update the last stroke
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
  }

  void endStroke() {
    // Stroke is already saved in history from startStroke
    // Clear the mirror pair tracking when stroke ends
    _mirrorPairStartIndex = null;
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
