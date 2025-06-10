import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/pages/scribble/scribble_painter.dart';
import 'package:lineleap/presentation/widgets/providers/scribble_notifier.dart';

class DrawingCanvas extends StatefulWidget {
  final EnhancedScribbleNotifier notifier;

  const DrawingCanvas({super.key, required this.notifier});

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        widget.notifier.startStroke(details.localPosition);
        HapticFeedback.selectionClick();
      },
      onPanUpdate: (details) {
        widget.notifier.appendPoint(details.localPosition);
      },
      onPanEnd: (details) {
        widget.notifier.endStroke();
      },
      child: CustomPaint(
        painter: EnhancedScribblePainter(widget.notifier.state.strokes),
        size: Size.infinite,
      ),
    );
  }
}
