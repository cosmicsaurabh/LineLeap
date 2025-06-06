import 'package:flutter/material.dart';

class Stroke {
  final List<Offset?> points;
  final Color color;
  Stroke({required this.points, required this.color});
}

class ScribbleNotifier extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Color _currentColor = Colors.black;
  Stroke? _currentStroke;
  get currentColor => _currentColor;

  List<Stroke> get strokes => List.unmodifiable(_strokes);

  // Color selection
  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  // Start a new stroke
  void startStroke(Offset point) {
    _currentStroke = Stroke(points: [point], color: _currentColor);
    notifyListeners();
  }

  // Add points to the current stroke
  void appendPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke!.points.add(point);
    notifyListeners();
  }

  // Finish the current stroke and add to history
  void endStroke() {
    if (_currentStroke == null) return;
    _strokes.add(_currentStroke!);
    _currentStroke = null;
    _redoStack.clear();
    notifyListeners();
  }

  // Clear all strokes
  void clear() {
    _strokes.clear();
    _redoStack.clear();
    _currentStroke = null;
    notifyListeners();
  }

  // Undo last stroke
  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
      notifyListeners();
    }
  }

  // Redo last undone stroke
  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
}

class Scribble extends StatelessWidget {
  final ScribbleNotifier notifier;
  final bool drawPen;

  const Scribble({super.key, required this.notifier, this.drawPen = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScribblePainter(notifier, drawPen),
      child: Container(),
    );
  }
}

class ScribblePainter extends CustomPainter {
  final ScribbleNotifier notifier;
  final bool drawPen;

  ScribblePainter(this.notifier, this.drawPen) : super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: Implement your drawing logic here
  }

  @override
  bool shouldRepaint(covariant ScribblePainter oldDelegate) {
    return oldDelegate.notifier != notifier || oldDelegate.drawPen != drawPen;
  }
}
