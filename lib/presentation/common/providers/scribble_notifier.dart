import 'package:flutter/material.dart';
import 'package:lineleap/presentation/features/scribble/scribble_page.dart';

class EnhancedScribbleNotifier extends ChangeNotifier {
  DrawingState _state = const DrawingState();
  DrawingState get state => _state;
  
  // Track the indices of strokes when in mirror mode
  // For vertical/horizontal: [original, mirrored]
  // For both: [original, vertical, horizontal, both]
  int? _mirrorStartIndex;
  int _mirrorStrokeCount = 0;

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
    // Cycle through: none -> vertical -> horizontal -> both -> none
    final nextMode = switch (_state.mirrorMode) {
      MirrorMode.none => MirrorMode.vertical,
      MirrorMode.vertical => MirrorMode.horizontal,
      MirrorMode.horizontal => MirrorMode.both,
      MirrorMode.both => MirrorMode.none,
    };
    _state = _state.copyWith(mirrorMode: nextMode);
    // Clear mirror tracking when toggling mirror mode
    _mirrorStartIndex = null;
    _mirrorStrokeCount = 0;
    notifyListeners();
  }

  void selectMirrorMode(MirrorMode mode) {
    if (_state.mirrorMode == mode) return;
    _state = _state.copyWith(mirrorMode: mode);
    _mirrorStartIndex = null;
    _mirrorStrokeCount = 0;
    notifyListeners();
  }

  void startStroke(Offset point, {double? canvasWidth, double? canvasHeight}) {
    final newStroke = Stroke(
      points: [point],
      color: _state.selectedColor,
      width: _state.brushStyle.width,
      style: _state.brushStyle,
    );

    List<Stroke> strokesToAdd = [newStroke];
    
    // If mirror mode is active, create mirrored strokes
    if (_state.mirrorMode.isActive && canvasWidth != null && canvasHeight != null) {
      final centerX = canvasWidth / 2;
      final centerY = canvasHeight / 2;
      
      // Track where we start adding mirrored strokes
      _mirrorStartIndex = _state.strokes.length;
      
      if (_state.mirrorMode == MirrorMode.vertical || _state.mirrorMode == MirrorMode.both) {
        // Vertical mirror: mirror across vertical center line
        final mirroredX = centerX * 2 - point.dx;
        final verticalMirror = Stroke(
          points: [Offset(mirroredX, point.dy)],
          color: _state.selectedColor,
          width: _state.brushStyle.width,
          style: _state.brushStyle,
        );
        strokesToAdd.add(verticalMirror);
      }
      
      if (_state.mirrorMode == MirrorMode.horizontal || _state.mirrorMode == MirrorMode.both) {
        // Horizontal mirror: mirror across horizontal center line
        final mirroredY = centerY * 2 - point.dy;
        final horizontalMirror = Stroke(
          points: [Offset(point.dx, mirroredY)],
          color: _state.selectedColor,
          width: _state.brushStyle.width,
          style: _state.brushStyle,
        );
        strokesToAdd.add(horizontalMirror);
      }
      
      if (_state.mirrorMode == MirrorMode.both) {
        // Both: mirror across both axes (diagonal mirror)
        final mirroredX = centerX * 2 - point.dx;
        final mirroredY = centerY * 2 - point.dy;
        final bothMirror = Stroke(
          points: [Offset(mirroredX, mirroredY)],
          color: _state.selectedColor,
          width: _state.brushStyle.width,
          style: _state.brushStyle,
        );
        strokesToAdd.add(bothMirror);
      }
      
      _mirrorStrokeCount = strokesToAdd.length - 1; // Number of mirrored strokes
    } else {
      _mirrorStartIndex = null;
      _mirrorStrokeCount = 0;
    }

    final newStrokes = [..._state.strokes, ...strokesToAdd];
    _saveToHistory(newStrokes);
  }

  void appendPoint(Offset point, {double? canvasWidth, double? canvasHeight}) {
    if (_state.strokes.isEmpty) return;

    // In mirror mode, update all mirrored strokes
    if (_state.mirrorMode.isActive && 
        canvasWidth != null && 
        canvasHeight != null &&
        _mirrorStartIndex != null &&
        _mirrorStartIndex! + _mirrorStrokeCount < _state.strokes.length) {
      final centerX = canvasWidth / 2;
      final centerY = canvasHeight / 2;
      
      final newStrokes = List<Stroke>.from(_state.strokes);
      
      // Update original stroke
      final originalStroke = _state.strokes[_mirrorStartIndex!];
      newStrokes[_mirrorStartIndex!] = originalStroke.copyWith(
        points: [...originalStroke.points, point],
      );
      
      int strokeIndex = _mirrorStartIndex! + 1;
      
      // Update vertical mirror (if applicable)
      if (_state.mirrorMode.hasVertical) {
        final mirroredX = centerX * 2 - point.dx;
        final verticalMirrorPoint = Offset(mirroredX, point.dy);
        final verticalStroke = _state.strokes[strokeIndex];
        newStrokes[strokeIndex] = verticalStroke.copyWith(
          points: [...verticalStroke.points, verticalMirrorPoint],
        );
        strokeIndex++;
      }
      
      // Update horizontal mirror (if applicable)
      // For "both" mode, horizontal comes after vertical, before diagonal
      if (_state.mirrorMode.hasHorizontal) {
        final mirroredY = centerY * 2 - point.dy;
        final horizontalMirrorPoint = Offset(point.dx, mirroredY);
        final horizontalStroke = _state.strokes[strokeIndex];
        newStrokes[strokeIndex] = horizontalStroke.copyWith(
          points: [...horizontalStroke.points, horizontalMirrorPoint],
        );
        strokeIndex++;
      }
      
      // Update diagonal mirror (only if both mode)
      if (_state.mirrorMode == MirrorMode.both) {
        final mirroredX = centerX * 2 - point.dx;
        final mirroredY = centerY * 2 - point.dy;
        final bothMirrorPoint = Offset(mirroredX, mirroredY);
        final bothStroke = _state.strokes[strokeIndex];
        newStrokes[strokeIndex] = bothStroke.copyWith(
          points: [...bothStroke.points, bothMirrorPoint],
        );
      }

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
    // Clear the mirror tracking when stroke ends
    _mirrorStartIndex = null;
    _mirrorStrokeCount = 0;
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
