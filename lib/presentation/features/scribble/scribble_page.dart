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
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';
import 'package:lineleap/presentation/common/dialogs/color_picker_dialog.dart'
    as color_dialog;
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum MirrorMode {
  none,
  vertical,
  horizontal,
  both;

  bool get hasVertical => this == vertical || this == both;
  bool get hasHorizontal => this == horizontal || this == both;
  bool get isActive => this != none;
}

class DrawingState {
  final List<Stroke> strokes;
  final Color selectedColor;
  final BrushStyle brushStyle;
  final List<List<Stroke>> history;
  final int historyIndex;
  final MirrorMode mirrorMode;

  const DrawingState({
    this.strokes = const [],
    this.selectedColor = Colors.grey,
    this.brushStyle = BrushStyle.medium,
    this.history = const [],
    this.historyIndex = -1,
    this.mirrorMode = MirrorMode.none,
  });

  DrawingState copyWith({
    List<Stroke>? strokes,
    Color? selectedColor,
    BrushStyle? brushStyle,
    List<List<Stroke>>? history,
    int? historyIndex,
    MirrorMode? mirrorMode,
  }) {
    return DrawingState(
      strokes: strokes ?? this.strokes,
      selectedColor: selectedColor ?? this.selectedColor,
      brushStyle: brushStyle ?? this.brushStyle,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      mirrorMode: mirrorMode ?? this.mirrorMode,
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

  static const String _pinnedToolsKey = 'scribble_pinned_tools';

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
    _loadPinnedTools();
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

  Future<void> _loadPinnedTools() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_pinnedToolsKey);
    if (stored == null || stored.isEmpty) return;

    final types = <ScribbleToolType>[];
    for (final id in stored) {
      final entry =
          scribbleToolRegistry.entries
              .firstWhere(
                (e) => e.value.id == id,
                orElse: () => scribbleToolRegistry.entries.first,
              )
              .key;
      if (!types.contains(entry)) {
        types.add(entry);
      }
    }
    if (types.isNotEmpty) {
      _notifier.setPinnedTools(types);
    }
  }

  Future<void> _savePinnedTools(List<ScribbleToolType> tools) async {
    final prefs = await SharedPreferences.getInstance();
    final ids =
        tools
            .map((t) => scribbleToolRegistry[t]?.id)
            .whereType<String>()
            .toList();
    await prefs.setStringList(_pinnedToolsKey, ids);
  }

  void updatePinnedTools(List<ScribbleToolType> tools) {
    _notifier.setPinnedTools(tools);
    _savePinnedTools(tools);
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
          Column(children: [_buildDrawingArea(theme, isDark)]),
          _buildPinnedToolsOverlay(theme),
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

  Widget _buildPinnedToolsOverlay(ThemeData theme) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, child) {
        final pinned = _notifier.pinnedTools;
        final hasPinned = pinned.isNotEmpty;

        return Positioned(
          right: 4,
          top: 12,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPinned) ...[
                  for (final type in pinned) ...[
                    _buildPinnedToolButton(type),
                    if (type != pinned.last) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 6),
                ],
                _buildMorePinnedButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinnedToolButton(ScribbleToolType type) {
    switch (type) {
      case ScribbleToolType.undo:
        return ActionButton(
          icon: CupertinoIcons.arrow_uturn_left,
          onPressed: _notifier.undo,
          style: ActionButtonStyle.secondary,
          showBorder: false,
          disabled: !_notifier.canUndo,
        );
      case ScribbleToolType.redo:
        return ActionButton(
          icon: CupertinoIcons.arrow_uturn_right,
          onPressed: _notifier.redo,
          style: ActionButtonStyle.secondary,
          showBorder: false,
          disabled: !_notifier.canRedo,
        );
      case ScribbleToolType.brush:
        return ActionButton(
          icon: CupertinoIcons.paintbrush,
          onPressed: () => _showBrushOptions(context),
          style: ActionButtonStyle.secondary,
          showBorder: false,
        );
      case ScribbleToolType.color:
        return ActionButton(
          icon: CupertinoIcons.color_filter,
          onPressed: () => _showColorPickerDialog(context),
          style: ActionButtonStyle.secondary,
          showBorder: false,
        );
      case ScribbleToolType.mirror:
        return ActionButton(
          icon: CupertinoIcons.square_split_2x2,
          onPressed: () => _cycleMirrorMode(),
          style:
              _notifier.state.mirrorMode.isActive
                  ? ActionButtonStyle.primary
                  : ActionButtonStyle.secondary,
          showBorder: false,
        );
      case ScribbleToolType.clear:
        return ActionButton(
          icon: CupertinoIcons.clear,
          onPressed: _notifier.clear,
          style: ActionButtonStyle.destructive,
          showBorder: false,
        );
      case ScribbleToolType.prompt:
        return ActionButton(
          icon: CupertinoIcons.textformat,
          onPressed: _showPromptDialog,
          style: ActionButtonStyle.primary,
          showBorder: false,
        );
      case ScribbleToolType.modelSelect:
        return ActionButton(
          icon: CupertinoIcons.square_list,
          onPressed: _showModelSelector,
          style: ActionButtonStyle.secondary,
          showBorder: false,
        );
    }
  }

  Widget _buildMorePinnedButton() {
    return ActionButton(
      icon: CupertinoIcons.ellipsis,
      onPressed: _showPinnedToolsSheet,
      style: ActionButtonStyle.secondary,
      showBorder: false,
    );
  }

  void _showPinnedToolsSheet() {
    final theme = Theme.of(context);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        var localPinned = List<ScribbleToolType>.from(_notifier.pinnedTools);
        var localMirror = _notifier.state.mirrorMode;

        return StatefulBuilder(
          builder: (context, setState) {
            Widget _buildPinChip({
              required ScribbleToolType type,
              required List<ScribbleToolType> localPinned,
              required void Function(void Function()) setState,
            }) {
              final config = scribbleToolRegistry[type]!;
              final isPinned = localPinned.contains(type);

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isPinned) {
                        localPinned.remove(type);
                      } else {
                        localPinned.add(type);
                      }
                    });
                    updatePinnedTools(localPinned);
                    HapticFeedback.selectionClick();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isPinned
                              ? theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              )
                              : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isPinned
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          config.icon,
                          size: 18,
                          color:
                              isPinned
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          config.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color:
                                isPinned
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isPinned
                              ? CupertinoIcons.pin_fill
                              : CupertinoIcons.pin,
                          size: 14,
                          color:
                              isPinned
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                top: false,
                child: CupertinoActionSheet(
                  title: const Text('Pinned tools'),
                  message: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Choose which tools stay on the canvas.'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mirror mode',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  localMirror = MirrorMode.vertical;
                                });
                                _notifier.selectMirrorMode(MirrorMode.vertical);
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      localMirror == MirrorMode.vertical
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.15)
                                          : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        localMirror == MirrorMode.vertical
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_left_right,
                                    size: 18,
                                    color:
                                        localMirror == MirrorMode.vertical
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  localMirror = MirrorMode.horizontal;
                                });
                                _notifier.selectMirrorMode(
                                  MirrorMode.horizontal,
                                );
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      localMirror == MirrorMode.horizontal
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.15)
                                          : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        localMirror == MirrorMode.horizontal
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_up_down,
                                    size: 18,
                                    color:
                                        localMirror == MirrorMode.horizontal
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  localMirror = MirrorMode.both;
                                });
                                _notifier.selectMirrorMode(MirrorMode.both);
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      localMirror == MirrorMode.both
                                          ? theme.colorScheme.primary
                                              .withValues(alpha: 0.15)
                                          : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        localMirror == MirrorMode.both
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                .withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.grid_4x4,
                                    size: 18,
                                    color:
                                        localMirror == MirrorMode.both
                                            ? theme.colorScheme.primary
                                            : theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Row 1: undo, redo, clear
                          Row(
                            children: [
                              _buildPinChip(
                                type: ScribbleToolType.undo,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const SizedBox(width: 8),
                              _buildPinChip(
                                type: ScribbleToolType.redo,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const SizedBox(width: 8),
                              _buildPinChip(
                                type: ScribbleToolType.clear,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 2: brush, color
                          Row(
                            children: [
                              _buildPinChip(
                                type: ScribbleToolType.brush,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const SizedBox(width: 8),
                              _buildPinChip(
                                type: ScribbleToolType.color,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 3: mirror tool
                          Row(
                            children: [
                              _buildPinChip(
                                type: ScribbleToolType.mirror,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Row 4: prompt, model
                          Row(
                            children: [
                              _buildPinChip(
                                type: ScribbleToolType.prompt,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const SizedBox(width: 8),
                              _buildPinChip(
                                type: ScribbleToolType.modelSelect,
                                localPinned: localPinned,
                                setState: setState,
                              ),
                              const Spacer(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        setState(() {
                          localPinned = List<ScribbleToolType>.from(
                            defaultPinnedTools,
                          );
                        });
                        updatePinnedTools(localPinned);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset to defaults'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    color_dialog.showColorPickerDialog(
      context: context,
      initialColor: _notifier.state.selectedColor,
      onColorSelected: _notifier.selectColor,
    );
  }

  void _showBrushOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Select Brush Style'),
            actions:
                BrushStyle.values.map((style) {
                  return CupertinoActionSheetAction(
                    onPressed: () {
                      _notifier.selectBrushStyle(style);
                      Navigator.pop(context);
                      HapticFeedback.selectionClick();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getBrushIcon(style)),
                        const SizedBox(width: 8),
                        Text(style.name),
                      ],
                    ),
                  );
                }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  IconData _getBrushIcon(BrushStyle style) {
    switch (style) {
      case BrushStyle.thin:
        return CupertinoIcons.pencil;
      case BrushStyle.medium:
        return CupertinoIcons.paintbrush;
      case BrushStyle.thick:
        return CupertinoIcons.paintbrush_fill;
      case BrushStyle.xtraThick:
        return Icons.format_paint;
      case BrushStyle.dotted:
        return Icons.more_horiz;
    }
  }

  void _cycleMirrorMode() {
    _notifier.toggleMirrorMode();
    HapticFeedback.selectionClick();
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
