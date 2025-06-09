import 'dart:typed_data';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/core/utils/image_utils.dart';
import 'package:flutter_scribble/data/remote/ai_horde_api.dart';
import 'package:flutter_scribble/data/repositories/image_generation_repository_impl.dart';
import 'package:flutter_scribble/domain/usecases/generate_image_usecase.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:flutter_scribble/presentation/widgets/providers/scribble_notifier.dart';
import 'package:flutter_scribble/presentation/widgets/theme_selector/theme_selector.dart';
import 'package:flutter_scribble/presentation/widgets/toolbar/scribble_toolbar.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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
  String prompt = '';

  Future<void> _handleGenerate() async {
    final galleryProvider = context.read<GalleryNotifier>();
    final bytes = await ImageUtils.capturePng(_paintKey);
    if (bytes == null) return;

    setState(() => isLoading = true);
    final api = AIHordeAPI();
    final imageRepository = ImageGenerationRepositoryImpl(api);
    final useCase = GenerateImageUseCase(imageRepository);
    final imageUrl = await useCase(bytes, prompt);

    Uint8List? finalImageBytes;
    if (imageUrl != null) {
      final res = await http.get(Uri.parse(imageUrl));
      if (res.statusCode == 200) {
        finalImageBytes = res.bodyBytes;
        galleryProvider.saveGeneratedImage(finalImageBytes, prompt);
      } else {
        // Handle error if image download fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download image: ${res.reasonPhrase}'),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }
    setState(() {
      generatedImage = finalImageBytes;
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
            const Text('Scribble'),
            const ThemeSelector(),
            if (!isLoading)
              ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : prompt.isNotEmpty
                        ? _handleGenerate
                        : () => promptHandling(),
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

          ScribbleToolbar(
            notifier: _notifier,
            onPrompt: promptHandling,
            onClear: _notifier.clear,
          ),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton:
          generatedImage != null
              ? FloatingActionButton(
                onPressed: () => _showGeneratedImagePopup(context),
                child: const Icon(Icons.image),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showGeneratedImagePopup(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Generated Image',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Prompt: $prompt', style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  Image.memory(generatedImage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> promptHandling() async {
    final result = await showTextInputDialog(
      context: context,
      title: 'Prompt Input',
      message: 'Enter prompt for AI generation',

      textFields: [
        DialogTextField(
          hintText: 'Express here',
          initialText: prompt,
          maxLines: 5,
          minLines: 1,
          validator:
              (value) =>
                  value?.isEmpty ?? true ? 'Prompt cannot be empty' : null,
        ),
      ],
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        prompt = result[0];
      });
    }
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
