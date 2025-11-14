import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:lineleap/presentation/features/queue/generating_queue_widget.dart';
import 'package:lineleap/theme/app_theme.dart';
import 'package:lineleap/presentation/features/scribble/drawing_canvas.dart';
import 'package:lineleap/presentation/features/scribble/model_selector_sheet.dart';
import 'package:lineleap/presentation/features/scribble/prompt_input_dialog.dart';
import 'package:lineleap/presentation/features/scribble/scribble_toolbar.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';

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
  final bool isMirrorMode;

  const DrawingState({
    this.strokes = const [],
    this.selectedColor = Colors.grey,
    this.brushStyle = BrushStyle.medium,
    this.history = const [],
    this.historyIndex = -1,
    this.isMirrorMode = false,
  });

  DrawingState copyWith({
    List<Stroke>? strokes,
    Color? selectedColor,
    BrushStyle? brushStyle,
    List<List<Stroke>>? history,
    int? historyIndex,
    bool? isMirrorMode,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      selectedColor: selectedColor ?? this.selectedColor,
      brushStyle: brushStyle ?? this.brushStyle,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      isMirrorMode: isMirrorMode ?? this.isMirrorMode,
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
  late AnimationController _typingController;

  String prompt = '';
  String selectedModel = 'Stable Diffusion';

  bool _isQueueVisible = false;
  Timer? _queueVisibilityTimer;
  bool _isQueueExpanded = false;

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
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _toolbarController.forward();
  }

  @override
  void dispose() {
    _notifier.dispose();
    _generateButtonController.dispose();
    _toolbarController.dispose();
    _typingController.dispose();
    _cancelQueueTimer(); // Cancel timer on dispose
    super.dispose();
  }

  void _startQueueTimer() {
    _queueVisibilityTimer?.cancel();
    if (_isQueueExpanded) return; // do nothing if they're looking at full view

    _queueVisibilityTimer = Timer(const Duration(seconds: 50), () {
      if (mounted) {
        setState(() {
          _isQueueVisible = false;
        });
      }
    });
  }

  void _cancelQueueTimer() {
    _queueVisibilityTimer?.cancel();
  }

  Future<void> _handleGenerate() async {
    final generationProvider = context.read<GenerationProvider>();
    if (prompt.isEmpty) {
      await _showPromptDialog();
      if (prompt.isEmpty) return;
    }
    generationProvider.sequenceForGenerationRequest(
      prompt: prompt,
      canvasKey: _paintKey,
    );
  }

  // void _showErrorSnackBar(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: Colors.red.shade600,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(AppTheme.smallRadius),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isCapturing = context.watch<GenerationProvider>().isCapturing;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark, isCapturing),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              _buildDrawingArea(theme, isDark),
              _buildToolbar(theme, isDark),
            ],
          ),
          Positioned(
            child: AnimatedOpacity(
              opacity: _isQueueVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child:
                  _isQueueVisible
                      ? GestureDetector(
                        onTap: _startQueueTimer, // Reset timer on tap
                        // onPanDown:
                        //     (_) =>
                        //         _startQueueTimer, // Reset on other interactions
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: _buildQueueOverlayWidget(context),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      // floatingActionButton: _buildFloatingActionButton(theme),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    bool isDark,
    bool isCapturing,
  ) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: GestureDetector(
        onTap: () {
          _typingController.reset();
          _typingController.forward();
          HapticFeedback.lightImpact();
        },
        child: Row(
          children: [
            Icon(
              CupertinoIcons.scribble,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            if (MediaQuery.of(context).size.width > 360)
              const SizedBox(width: 8),
            if (MediaQuery.of(context).size.width > 360)
              _TypingText(
                text: 'LineLeap',
                controller: _typingController,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
      actions: [
        _buildThemeToggle(theme, isDark),
        const SizedBox(width: 8),
        // _buildGenerateButton(theme),
        ActionButton(
          icon: isCapturing ? CupertinoIcons.stop : CupertinoIcons.add,
          onPressed:
              isCapturing
                  ? () {
                    log('Generate button pressed while loading');
                  }
                  : () {
                    log('Generate button pressed while not loading');
                    _generateButtonController.forward().then((_) {
                      _generateButtonController.reverse();
                    });
                    _handleGenerate();
                    HapticFeedback.selectionClick();
                  },
          style:
              isCapturing
                  ? ActionButtonStyle.secondary
                  : ActionButtonStyle.primary,

          // label: 'Clear Canvas',
        ),
        const SizedBox(width: 8),
        ActionButton(
          icon: CupertinoIcons.list_bullet,
          onPressed: () {
            setState(() {
              _isQueueVisible = !_isQueueVisible;
              if (_isQueueVisible) {
                _startQueueTimer(); // Start timer when queue is shown
              } else {
                _cancelQueueTimer(); // Cancel timer when queue is hidden
              }
            });
            HapticFeedback.selectionClick();
          },
          // label: 'View Queue',
          style: ActionButtonStyle.secondary,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQueueOverlayWidget(BuildContext context) {
    final queueProvider = Provider.of<QueueStatusProvider>(
      context,
      listen:
          false, // listen:false is fine as Consumer below will handle updates
    );
    final galleryNotifier = Provider.of<GalleryNotifier>(
      context,
      listen: false,
    );

    return Consumer<QueueStatusProvider>(
      builder: (context, provider, child) {
        // The GenerationQueueWidget should ideally be scrollable if items exceed maxHeight
        return GenerationQueueWidget(
          onExpansionChanged: (isExpanded) {
            setState(() {
              _isQueueExpanded = isExpanded;
            });
          },
          queueItems: provider.queueItems,
          refreshQueue: provider.refreshQueue,
          onRemove: (request) {
            provider.removeFromQueue(request);
            _startQueueTimer(); // Reset timer on interaction
          },
          onRetry: (request) {
            provider.retryGeneration(request);
            _startQueueTimer(); // Reset timer on interaction
          },
          onDownload: (request) async {
            _cancelQueueTimer(); // Pause timer during async operation
            bool success = await galleryNotifier.saveToHistory(
              scribblePath: request.scribblePath,
              generatedPath: request.generatedPath!,
              prompt: request.prompt,
              timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
            );
            if (success) {
              queueProvider.removeFromQueue(request);
            }
            if (mounted && _isQueueVisible) _startQueueTimer(); // Resume timer
          },
          onView: (request) {
            _cancelQueueTimer(); // Pause timer while dialog is open
            showDialog(
              context: context,
              barrierColor: Colors.black.withValues(alpha: 0.1),
              builder:
                  (context) => GalleryImageDialog(
                    scribbleTransformation: ScribbleTransformation(
                      generatedImagePath: request.generatedPath!,
                      scribbleImagePath: request.scribblePath,
                      prompt: request.prompt,
                      timestamp: request.createdAt?.toIso8601String() ?? "-",
                    ),
                    gallery: galleryNotifier,
                    whichImage: 0,
                  ),
            ).then((_) {
              if (mounted && _isQueueVisible) {
                _startQueueTimer();
              } // Resume timer when dialog closes
            });
          },
        );
      },
    );
  }

  Widget _buildThemeToggle(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
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

  // Widget _buildGenerateButton(ThemeData theme) {
  //   return AnimatedBuilder(
  //     animation: _generateButtonController,
  //     builder: (context, child) {
  //       return Transform.scale(
  //         scale: 1.0 - (_generateButtonController.value * 0.1),
  //         child: Container(
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               colors: [
  //                 theme.colorScheme.primary,
  //                 theme.colorScheme.primary.withOpacity(0.8),
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(20),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: theme.colorScheme.primary.withOpacity(0.3),
  //                 blurRadius: 8,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               borderRadius: BorderRadius.circular(20),
  //               onTap:
  //                   isCapturing
  //                       ? null
  //                       : () {
  //                         _generateButtonController.forward().then((_) {
  //                           _generateButtonController.reverse();
  //                         });
  //                         _handleGenerate();
  //                       },
  //               child: Padding(
  //                 padding: const EdgeInsets.symmetric(
  //                   horizontal: 16,
  //                   vertical: 12,
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     if (isCapturing)
  //                       SizedBox(
  //                         width: 16,
  //                         height: 16,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           valueColor: AlwaysStoppedAnimation(
  //                             theme.colorScheme.onPrimary,
  //                           ),
  //                         ),
  //                       )
  //                     else
  //                       Icon(
  //                         CupertinoIcons.sparkles,
  //                         size: 16,
  //                         color: theme.colorScheme.onPrimary,
  //                       ),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       isCapturing ? 'Generating...' : 'Generate',
  //                       style: TextStyle(
  //                         color: theme.colorScheme.onPrimary,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildDrawingArea(ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.8,
                ),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
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

class _TypingText extends StatefulWidget {
  final String text;
  final AnimationController controller;
  final TextStyle? style;

  const _TypingText({required this.text, required this.controller, this.style});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final progress = widget.controller.value;
        final charCount = (progress * widget.text.length).floor();
        final displayedText = widget.text.substring(
          0,
          charCount.clamp(0, widget.text.length),
        );

        return Text(displayedText, style: widget.style);
      },
    );
  }
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
