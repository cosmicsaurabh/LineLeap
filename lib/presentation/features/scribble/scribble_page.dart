import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/theme/app_theme.dart';
import 'package:lineleap/core/utils/image_utils.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/features/queue/queue_screen.dart';
import 'package:lineleap/presentation/features/scribble/drawing_canvas.dart';
import 'package:lineleap/presentation/features/scribble/model_selector_sheet.dart';
import 'package:lineleap/presentation/features/scribble/prompt_input_dialog.dart';
import 'package:lineleap/presentation/features/scribble/scribble_toolbar.dart';
import 'package:lineleap/presentation/common/widgets/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/widgets/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/widgets/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/widgets/providers/theme_notifier.dart';
import 'package:provider/provider.dart';

enum BrushStyle {
  thin(2.0, 'Thin'),
  medium(4.0, 'Medium'),
  thick(8.0, 'Thick'),
  xtraThick(12.0, 'Extra Thick'),
  dotted(3.0, 'Dotted');

  const BrushStyle(this.width, this.name);
  final double width;
  final String name;
}

class DrawingState {
  final List<Stroke> strokes;
  final Color selectedColor;
  final BrushStyle brushStyle;
  final List<List<Stroke>> history;
  final int historyIndex;

  const DrawingState({
    this.strokes = const [],
    this.selectedColor = Colors.grey,
    this.brushStyle = BrushStyle.medium,
    this.history = const [],
    this.historyIndex = -1,
  });

  DrawingState copyWith({
    List<Stroke>? strokes,
    Color? selectedColor,
    BrushStyle? brushStyle,
    List<List<Stroke>>? history,
    int? historyIndex,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      selectedColor: selectedColor ?? this.selectedColor,
      brushStyle: brushStyle ?? this.brushStyle,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
    );
  }
}

class ScribblePage extends StatefulWidget {
  const ScribblePage({super.key});

  @override
  State<ScribblePage> createState() => _ScribblePageState();
}

class _ScribblePageState extends State<ScribblePage>
    with TickerProviderStateMixin {
  final EnhancedScribbleNotifier _notifier = EnhancedScribbleNotifier();
  final GlobalKey _paintKey = GlobalKey();

  late AnimationController _generateButtonController;
  late AnimationController _toolbarController;

  bool isLoading = false;
  String prompt = '';
  String selectedModel = 'Stable Diffusion';

  @override
  void initState() {
    super.initState();
    _generateButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarController.forward();
  }

  @override
  void dispose() {
    _notifier.dispose();
    _generateButtonController.dispose();
    _toolbarController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerate() async {
    final galleryProvider = context.read<GalleryNotifier>();
    final generationProvider = context.read<GenerationProvider>();
    if (prompt.isEmpty) {
      await _showPromptDialog();
      if (prompt.isEmpty) return;
    }

    setState(() => isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // 1. Capture the scribble image
      final scribbleBytes = await ImageUtils.capturePng(_paintKey);
      if (scribbleBytes == null) {
        setState(() => isLoading = false);
        return;
      }

      // 2. Save the scribble to a temporary file
      final String scribblePath = await galleryProvider.saveImage(
        scribbleBytes,
      );

      // 3. Enqueue the generation request via the provider
      final request = await generationProvider.generateImage(
        prompt: prompt,
        scribblePath: scribblePath,
      );

      // 4. Poll for completion
      await _watchRequestUntilComplete(request.localId, scribbleBytes);
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Generation failed: $e');
    }
  }

  Future<void> _watchRequestUntilComplete(
    String requestId,
    Uint8List originalScribble,
  ) async {
    final generationProvider = context.read<GenerationProvider>();
    final galleryProvider = context.read<GalleryNotifier>();

    bool isComplete = false;
    int attempts = 0;
    const maxAttempts = 60; // Timeout after 60 seconds

    while (!isComplete && attempts < maxAttempts) {
      attempts++;
      await Future.delayed(const Duration(seconds: 2));

      final request = await generationProvider.getRequest(requestId);

      // Check if request completed or failed
      if (request?.status == GenerationStatus.completed) {
        if (request?.generatedPath != null) {
          final generatedBytes =
              await File(request!.generatedPath!).readAsBytes();

          // Save to gallery
          galleryProvider.saveImage(generatedBytes);

          // Update UI
          setState(() {
            isLoading = false;
          });

          // await _showGeneratedImageDialog();
          isComplete = true;
          HapticFeedback.heavyImpact();
        }
      } else if (request?.status == GenerationStatus.failed) {
        _showErrorSnackBar(
          'Generation failed: ${request?.error ?? "Unknown error"}',
        );
        setState(() => isLoading = false);
        isComplete = true;
      } else if (request == null) {
        _showErrorSnackBar('Request was removed from queue');
        setState(() => isLoading = false);
        isComplete = true;
      }
    }

    if (!isComplete) {
      _showErrorSnackBar('Generation timed out');
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.queue),
            title: const Text('Queue Status'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueueScreen()),
              );
            },
          ),
          _buildDrawingArea(theme, isDark),
          _buildToolbar(theme, isDark),
        ],
      ),
      // floatingActionButton: _buildFloatingActionButton(theme),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            CupertinoIcons.scribble,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          if (MediaQuery.of(context).size.width > 360) const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width > 360)
            Text(
              'LineLeap',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
      actions: [
        _buildThemeToggle(theme, isDark),
        const SizedBox(width: 8),
        _buildGenerateButton(theme),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildThemeToggle(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () {
          context.read<ThemeNotifier>().setThemeMode(
            isDark ? ThemeMode.light : ThemeMode.dark,
          );
          HapticFeedback.selectionClick();
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
            key: ValueKey(isDark),
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _generateButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (_generateButtonController.value * 0.1),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    isLoading
                        ? null
                        : () {
                          _generateButtonController.forward().then((_) {
                            _generateButtonController.reverse();
                          });
                          _handleGenerate();
                        },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      else
                        Icon(
                          CupertinoIcons.sparkles,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        isLoading ? 'Generating...' : 'Generate',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawingArea(ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: RepaintBoundary(
            key: _paintKey,
            child: DrawingCanvas(notifier: _notifier),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _toolbarController, curve: Curves.easeOutCubic),
      ),
      child: Container(
        height: AppTheme.toolbarHeight,
        margin: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: ScribbleToolbar(
                notifier: _notifier,
                onPrompt: _showPromptDialog,
                onModelSelect: _showModelSelector,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget? _buildFloatingActionButton(ThemeData theme) {
  //   if (generatedImage == null) return null;

  //   return FloatingActionButton(
  //     onPressed: _showGeneratedImageDialog,
  //     backgroundColor: theme.colorScheme.secondary,
  //     child: Icon(CupertinoIcons.photo, color: theme.colorScheme.onSecondary),
  //   );
  // }

  Future<void> _showPromptDialog() async {
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => PromptInputDialog(initialPrompt: prompt),
    );

    if (result != null) {
      setState(() => prompt = result);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _showModelSelector() async {
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => ModelSelectorSheet(selectedModel: selectedModel),
    );

    if (result != null) {
      setState(() => selectedModel = result);
      HapticFeedback.selectionClick();
    }
  }

  // Future<void> _showGeneratedImageDialog() async {
  //   if (generatedImage == null) return;

  //   await showDialog(
  //     context: context,
  //     builder:
  //         (context) =>
  //             GeneratedImageViewer(image: generatedImage!, prompt: prompt),
  //   );
  // }
}

// Usage Example and Integration
class ScribbleApp extends StatelessWidget {
  const ScribbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scribble AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ScribblePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
