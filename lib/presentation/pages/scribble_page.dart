import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/core/utils/image_utils.dart';
import 'package:flutter_scribble/data/remote/replicate_api.dart';
import 'package:flutter_scribble/domain/usecases/generate_image_usecase.dart';
import 'package:flutter_scribble/presentation/widgets/color_picker.dart';
import 'package:flutter_scribble/presentation/widgets/scribble_notifier.dart';

class ScribblePage extends StatefulWidget {
  const ScribblePage({super.key});

  @override
  State<ScribblePage> createState() => _ScribblePageState();
}

class _ScribblePageState extends State<ScribblePage> {
  final ScribbleNotifier _notifier = ScribbleNotifier();
  final GlobalKey _paintKey = GlobalKey();

  Uint8List? generatedImage;
  bool isLoading = false;

  Future<void> _handleGenerate() async {
    final bytes = await ImageUtils.capturePng(_paintKey);
    if (bytes == null) return;

    setState(() => isLoading = true);

    final api = ReplicateAPI();
    final useCase = GenerateImageUseCase(api);
    final result = await useCase.generateFromSketch(
      bytes,
      "a cute cat in watercolor style",
    );

    setState(() {
      generatedImage = result;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scribble to AI Image'),
            if (!isLoading)
              ElevatedButton.icon(
                onPressed: isLoading ? null : _handleGenerate,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("Generate"),
              ),
            if (isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: RepaintBoundary(
              key: _paintKey,
              child: Scribble(notifier: _notifier),
            ),
          ),
          ColorPicker(onColorSelected: _notifier.setColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _notifier.clear,
                icon: const Icon(Icons.clear),
                label: const Text("Clear"),
              ),
              Tooltip(
                message: "Undo",
                waitDuration: const Duration(milliseconds: 500),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _notifier.canUndo ? _notifier.undo : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.undo,
                        color:
                            _notifier.canUndo
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Tooltip(
                message: "Redo",
                waitDuration: const Duration(milliseconds: 500),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _notifier.canRedo ? _notifier.redo : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.redo,
                        color:
                            _notifier.canRedo
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (generatedImage != null)
            Expanded(flex: 2, child: Image.memory(generatedImage!)),
        ],
      ),
    );
  }
}

class Scribble extends StatefulWidget {
  final ScribbleNotifier notifier;
  const Scribble({super.key, required this.notifier});

  @override
  State<Scribble> createState() => _ScribbleState();
}

class _ScribbleState extends State<Scribble> {
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
      },
      onPanUpdate: (details) {
        widget.notifier.appendPoint(details.localPosition);
      },
      onPanEnd: (details) {
        widget.notifier.endStroke();
      },
      child: CustomPaint(
        painter: _ScribblePainter(widget.notifier.strokes),
        size: Size.infinite,
      ),
    );
  }
}

class _ScribblePainter extends CustomPainter {
  final List<Stroke> strokes;
  _ScribblePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint =
          Paint()
            ..color = stroke.color
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ScribblePainter oldDelegate) => true;
}
