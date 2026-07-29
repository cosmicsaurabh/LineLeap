import 'package:flutter/material.dart';
import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/config/mirrot_mode.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/domain/entities/drawing_state.dart';
import 'package:lineleap/domain/entities/stroke.dart';
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';

class EnhancedScribbleNotifier extends ChangeNotifier {
  DrawingState _state = const DrawingState();
  DrawingState get state => _state;

  // Pinned tools
  List<ScribbleToolType> _pinnedTools = List<ScribbleToolType>.from(
    defaultPinnedTools,
  );

  List<ScribbleToolType> get pinnedTools => List.unmodifiable(_pinnedTools);

  // Track the indices of strokes when in mirror mode
  // For vertical/horizontal: [original, mirrored]
  // For both: [original, vertical, horizontal, both]
  int? _mirrorStartIndex;
  int _mirrorStrokeCount = 0;
  bool _strokeInProgress = false;

  bool get canUndo => _state.historyIndex > 0;
  bool get canRedo => _state.historyIndex < _state.history.length - 1;

  void setPinnedTools(List<ScribbleToolType> tools) {
    _pinnedTools = List<ScribbleToolType>.from(tools);
    notifyListeners();
  }

  void selectColor(Color color) {
    _state = _state.copyWith(selectedColor: color);
    notifyListeners();
  }

  void selectBrushStyle(BrushStyle style) {
    _state = _state.copyWith(brushStyle: style);
    notifyListeners();
  }

  void toggleMirrorMode() {
    _commitActiveStroke();

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
    _commitActiveStroke();
    _state = _state.copyWith(mirrorMode: mode);
    _mirrorStartIndex = null;
    _mirrorStrokeCount = 0;
    notifyListeners();
  }

  void startStroke(Offset point, {double? canvasWidth, double? canvasHeight}) {
    _commitActiveStroke();

    final newStroke = Stroke(
      points: [point],
      color: _state.selectedColor,
      width: _state.brushStyle.width,
      style: _state.brushStyle,
    );

    List<Stroke> strokesToAdd = [newStroke];

    // If mirror mode is active, create mirrored strokes
    if (_state.mirrorMode.isActive &&
        canvasWidth != null &&
        canvasHeight != null) {
      final centerX = canvasWidth / 2;
      final centerY = canvasHeight / 2;

      // Track where we start adding mirrored strokes
      _mirrorStartIndex = _state.strokes.length;

      if (_state.mirrorMode == MirrorMode.vertical ||
          _state.mirrorMode == MirrorMode.both) {
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

      if (_state.mirrorMode == MirrorMode.horizontal ||
          _state.mirrorMode == MirrorMode.both) {
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

      _mirrorStrokeCount =
          strokesToAdd.length - 1; // Number of mirrored strokes
    } else {
      _mirrorStartIndex = null;
      _mirrorStrokeCount = 0;
    }

    final newStrokes = [..._state.strokes, ...strokesToAdd];
    _strokeInProgress = true;
    _saveToHistory(newStrokes);
  }

  void appendPoint(Offset point, {double? canvasWidth, double? canvasHeight}) {
    if (!_strokeInProgress || _state.strokes.isEmpty) return;

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
    if (!_commitActiveStroke()) return;
    notifyListeners();
  }

  void undo() {
    _commitActiveStroke();

    if (!canUndo) return;

    final newIndex = _state.historyIndex - 1;
    _state = _state.copyWith(
      strokes: _state.history[newIndex],
      historyIndex: newIndex,
    );
    notifyListeners();
  }

  void redo() {
    final committedStroke = _commitActiveStroke();

    if (!canRedo) {
      if (committedStroke) notifyListeners();
      return;
    }

    final newIndex = _state.historyIndex + 1;
    _state = _state.copyWith(
      strokes: _state.history[newIndex],
      historyIndex: newIndex,
    );
    notifyListeners();
  }

  void clear() {
    _commitActiveStroke();
    _saveToHistory([]);
  }

  void _saveToHistory(List<Stroke> strokes) {
    final strokeSnapshot = List<Stroke>.unmodifiable(strokes);
    final newHistory = _state.history.take(_state.historyIndex + 1).toList();
    newHistory.add(strokeSnapshot);

    _state = _state.copyWith(
      strokes: strokeSnapshot,
      history: List<List<Stroke>>.unmodifiable(newHistory),
      historyIndex: newHistory.length - 1,
    );
    notifyListeners();
  }

  bool _commitActiveStroke() {
    if (!_strokeInProgress) return false;

    final completedStrokes = List<Stroke>.unmodifiable(_state.strokes);
    final newHistory = List<List<Stroke>>.from(_state.history);
    newHistory[_state.historyIndex] = completedStrokes;

    _state = _state.copyWith(
      strokes: completedStrokes,
      history: List<List<Stroke>>.unmodifiable(newHistory),
    );
    _strokeInProgress = false;
    _mirrorStartIndex = null;
    _mirrorStrokeCount = 0;
    return true;
  }
}
