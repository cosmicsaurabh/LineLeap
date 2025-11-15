import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/features/scribble/scribble_painter.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;
        return GestureDetector(
          onPanStart: (details) {
            widget.notifier.startStroke(
              details.localPosition,
              canvasWidth: canvasWidth,
              canvasHeight: canvasHeight,
            );
            HapticFeedback.selectionClick();
          },
          onPanUpdate: (details) {
            widget.notifier.appendPoint(
              details.localPosition,
              canvasWidth: canvasWidth,
              canvasHeight: canvasHeight,
            );
          },
          onPanEnd: (details) {
            widget.notifier.endStroke();
          },
          child: CustomPaint(
            painter: EnhancedScribblePainter(
              widget.notifier.state.strokes,
              mirrorMode: widget.notifier.state.mirrorMode,
              canvasWidth: canvasWidth,
              canvasHeight: canvasHeight,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}
