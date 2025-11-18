import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/presentation/common/widgets/theme_selector/theme_selector.dart';
import 'package:lineleap/presentation/features/typing_text/typing_text.dart';
import 'package:provider/provider.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/features/scribble/model_selector_sheet.dart';
import 'package:lineleap/presentation/features/scribble/prompt_input_dialog.dart';
import 'package:lineleap/presentation/features/scribble/pinned_toolbar_overlay.dart';
import 'package:lineleap/presentation/features/scribble/pinned_tools_sheet.dart';
import 'package:lineleap/presentation/features/scribble/queue_overlay_widget.dart';
import 'package:lineleap/presentation/features/scribble/scribble_drawing_area.dart';
import 'package:lineleap/presentation/features/scribble/scribble_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isCapturing = context.watch<GenerationProvider>().isCapturing;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme, isDark, isCapturing),
      body: Stack(
        children: [
          ScribbleDrawingArea(
            notifier: _notifier,
            paintKey: _paintKey,
            theme: theme,
            isDark: isDark,
          ),
          PinnedToolbarOverlay(
            notifier: _notifier,
            onPrompt: _showPromptDialog,
            onModelSelect: _showModelSelector,
            onShowPinnedToolsSheet: _showPinnedToolsSheet,
          ),
          QueueOverlayWidget(
            isVisible: _isQueueVisible,
            isExpanded: _isQueueExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isQueueExpanded = expanded;
              });
            },
            onTimerReset: _startQueueTimer,
            onTimerCancel: _cancelQueueTimer,
          ),
        ],
      ),
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
              TypingText(
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
        buildThemeToggle(theme, isDark, context),
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

  void _showPinnedToolsSheet() {
    showPinnedToolsSheet(
      context: context,
      pinnedTools: _notifier.pinnedTools,
      mirrorMode: _notifier.state.mirrorMode,
      onPinnedToolsChanged: updatePinnedTools,
      onMirrorModeChanged: _notifier.selectMirrorMode,
    );
  }

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
