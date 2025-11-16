// Scribble Toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';
import 'package:lineleap/presentation/features/scribble/scribble_page.dart';
import 'package:lineleap/presentation/common/dialogs/color_picker_dialog.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

class ScribbleToolbar extends StatefulWidget {
  final EnhancedScribbleNotifier notifier;
  final VoidCallback onPrompt;
  final VoidCallback onModelSelect;

  const ScribbleToolbar({
    super.key,
    required this.notifier,
    required this.onPrompt,
    required this.onModelSelect,
  });

  @override
  State<ScribbleToolbar> createState() => _ScribbleToolbarState();
}

class _ScribbleToolbarState extends State<ScribbleToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _withSpacing(_buildToolbarGroups(theme)),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildToolbarGroups(ThemeData theme) {
    return [
      _buildHistoryGroup(),
      _buildCanvasGroup(),
      _buildCreativeGroup(),
      _buildSymmetryGroup(theme),
    ];
  }

  Widget _buildHistoryGroup() {
    return _ToolbarGroup(
      icon: CupertinoIcons.time,
      label: 'History',
      children: [
        _buildUndoButton(),
        _buildRedoButton(),
        _buildClearButton(),
      ],
    );
  }

  Widget _buildCanvasGroup() {
    return _ToolbarGroup(
      icon: CupertinoIcons.paintbrush,
      label: 'Canvas',
      children: [
        _buildBrushButton(),
        _buildColorButton(),
      ],
    );
  }

  Widget _buildCreativeGroup() {
    return _ToolbarGroup(
      icon: CupertinoIcons.sparkles,
      label: 'Creative',
      children: [
        _buildPromptButton(),
        _buildModelButton(),
      ],
    );
  }

  Widget _buildSymmetryGroup(ThemeData theme) {
    return _ToolbarGroup(
      icon: CupertinoIcons.square_split_2x2,
      label: 'Symmetry',
      children: [
        _buildMirrorSelector(theme),
      ],
    );
  }

  Widget _buildUndoButton() {
    return Tooltip(
      message: 'Undo',
      child: ActionButton(
        icon: CupertinoIcons.arrow_uturn_left,
        onPressed: widget.notifier.undo,
        style: ActionButtonStyle.secondary,
        showBorder: false,
        disabled: !widget.notifier.canUndo,
      ),
    );
  }

  Widget _buildRedoButton() {
    return Tooltip(
      message: 'Redo',
      child: ActionButton(
        icon: CupertinoIcons.arrow_uturn_right,
        onPressed: widget.notifier.redo,
        style: ActionButtonStyle.secondary,
        showBorder: false,
        disabled: !widget.notifier.canRedo,
      ),
    );
  }

  Widget _buildClearButton() {
    return Tooltip(
      message: 'Clear canvas',
      child: ActionButton(
        icon: CupertinoIcons.clear,
        onPressed: widget.notifier.clear,
        style: ActionButtonStyle.destructive,
        showBorder: false,
      ),
    );
  }

  Widget _buildBrushButton() {
    return Tooltip(
      message: widget.notifier.state.brushStyle.name,
      child: ActionButton(
        onPressed: () => _showBrushOptions(context),
        icon: _getBrushIcon(widget.notifier.state.brushStyle),
        style: ActionButtonStyle.secondary,
        showBorder: false,
      ),
    );
  }

  Widget _buildColorButton() {
    final selectedColor = widget.notifier.state.selectedColor;
    return Tooltip(
      message: 'Color',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ActionButton(
            icon: CupertinoIcons.color_filter,
            onPressed: () => showColorPickerDialog(
              context: context,
              initialColor: selectedColor,
              onColorSelected: widget.notifier.selectColor,
            ),
            style: ActionButtonStyle.secondary,
            showBorder: false,
          ),
          Positioned(
            top: -2,
            right: -2,
            child: _ColorBadge(color: selectedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptButton() {
    return Tooltip(
      message: 'Open prompt',
      child: ActionButton(
        icon: CupertinoIcons.textformat,
        onPressed: widget.onPrompt,
        style: ActionButtonStyle.primary,
        showBorder: false,
      ),
    );
  }

  Widget _buildModelButton() {
    return Tooltip(
      message: 'Select model',
      child: ActionButton(
        icon: CupertinoIcons.square_list,
        onPressed: widget.onModelSelect,
        style: ActionButtonStyle.secondary,
        showBorder: false,
      ),
    );
  }

  Widget _buildMirrorSelector(ThemeData theme) {
    final mirrorMode = widget.notifier.state.mirrorMode;
    return Tooltip(
      message: _getMirrorTooltip(mirrorMode),
      child: SizedBox(
        width: 220,
        child: CupertinoSlidingSegmentedControl<MirrorMode>(
          groupValue: mirrorMode,
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.4),
          thumbColor: theme.colorScheme.primary.withValues(alpha: 0.9),
          children: const {
            MirrorMode.none: Icon(CupertinoIcons.xmark),
            MirrorMode.vertical: Icon(CupertinoIcons.arrow_left_right),
            MirrorMode.horizontal: Icon(CupertinoIcons.arrow_up_down),
            MirrorMode.both: Icon(Icons.grid_4x4),
          },
          onValueChanged: (mode) {
            if (mode == null) return;
            widget.notifier.selectMirrorMode(mode);
            HapticFeedback.selectionClick();
          },
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> widgets, {double spacing = 12}) {
    if (widgets.isEmpty) return widgets;
    final spaced = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      spaced.add(widgets[i]);
      if (i != widgets.length - 1) {
        spaced.add(SizedBox(width: spacing));
      }
    }
    return spaced;
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

  IconData _getMirrorIcon(MirrorMode mode) {
    switch (mode) {
      case MirrorMode.none:
        return CupertinoIcons.arrow_left_right;
      case MirrorMode.vertical:
        return CupertinoIcons.arrow_left_right;
      case MirrorMode.horizontal:
        return CupertinoIcons.arrow_up_down;
      case MirrorMode.both:
        return Icons.grid_4x4; // Use Material icon for both mode
    }
  }

  String _getMirrorTooltip(MirrorMode mode) {
    switch (mode) {
      case MirrorMode.none:
        return 'Mirror: Off';
      case MirrorMode.vertical:
        return 'Mirror: Vertical';
      case MirrorMode.horizontal:
        return 'Mirror: Horizontal';
      case MirrorMode.both:
        return 'Mirror: Both';
    }
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
                      widget.notifier.selectBrushStyle(style);
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
}

class _ToolbarGroup extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Widget> children;

  const _ToolbarGroup({
    required this.icon,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.25);
    final background =
        theme.colorScheme.surface.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (children.isNotEmpty) const SizedBox(width: 12),
          ..._intersperse(children),
        ],
      ),
    );
  }

  List<Widget> _intersperse(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(const SizedBox(width: 8));
      }
    }
    return result;
  }
}

class _ColorBadge extends StatelessWidget {
  final Color color;

  const _ColorBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: const SizedBox(width: 16, height: 16),
    );
  }
}
