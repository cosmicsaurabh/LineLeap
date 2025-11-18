import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/config/tool_item.dart';
import 'package:lineleap/presentation/common/dialogs/color_picker_dialog.dart'
    as color_dialog;
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/utils/responsive_layout_helper.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';

class PinnedToolbarOverlay extends StatelessWidget {
  final EnhancedScribbleNotifier notifier;
  final VoidCallback onPrompt;
  final VoidCallback onModelSelect;
  final VoidCallback onShowPinnedToolsSheet;

  const PinnedToolbarOverlay({
    super.key,
    required this.notifier,
    required this.onPrompt,
    required this.onModelSelect,
    required this.onShowPinnedToolsSheet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = ResponsiveLayoutHelper(context);
    final toolbarPosition = responsive.getToolbarPosition();
    
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, child) {
        final pinned = notifier.pinnedTools;
        final hasPinned = pinned.isNotEmpty;

        // In landscape/low height, use horizontal layout at bottom
        if (toolbarPosition == ToolbarPosition.bottom) {
          return Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasPinned) ...[
                      for (final type in pinned) ...[
                        _buildPinnedToolButton(context, theme, type),
                        if (type != pinned.last) const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 6),
                      Container(
                        width: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildMorePinnedButton(),
                  ],
                ),
              ),
            ),
          );
        }

        // Default: vertical layout on right side
        return Positioned(
          right: 4,
          top: 12,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasPinned) ...[
                  for (final type in pinned) ...[
                    _buildPinnedToolButton(context, theme, type),
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

  Widget _buildPinnedToolButton(
    BuildContext context,
    ThemeData theme,
    ScribbleToolType type,
  ) {
    switch (type) {
      case ScribbleToolType.undo:
        return ActionButton(
          icon: CupertinoIcons.arrow_uturn_left,
          onPressed: notifier.undo,
          style: ActionButtonStyle.secondary,
          showBorder: false,
          disabled: !notifier.canUndo,
        );
      case ScribbleToolType.redo:
        return ActionButton(
          icon: CupertinoIcons.arrow_uturn_right,
          onPressed: notifier.redo,
          style: ActionButtonStyle.secondary,
          showBorder: false,
          disabled: !notifier.canRedo,
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
              notifier.state.mirrorMode.isActive
                  ? ActionButtonStyle.primary
                  : ActionButtonStyle.secondary,
          showBorder: false,
        );
      case ScribbleToolType.clear:
        return ActionButton(
          icon: CupertinoIcons.clear,
          onPressed: notifier.clear,
          style: ActionButtonStyle.destructive,
          showBorder: false,
        );
      case ScribbleToolType.prompt:
        return ActionButton(
          icon: CupertinoIcons.textformat,
          onPressed: onPrompt,
          style: ActionButtonStyle.primary,
          showBorder: false,
        );
      case ScribbleToolType.model:
        return ActionButton(
          icon: CupertinoIcons.square_list,
          onPressed: onModelSelect,
          style: ActionButtonStyle.secondary,
          showBorder: false,
        );
    }
  }

  Widget _buildMorePinnedButton() {
    return ActionButton(
      icon: CupertinoIcons.ellipsis,
      onPressed: onShowPinnedToolsSheet,
      style: ActionButtonStyle.secondary,
      showBorder: false,
    );
  }

  void _showColorPickerDialog(BuildContext context) {
    color_dialog.showColorPickerDialog(
      context: context,
      initialColor: notifier.state.selectedColor,
      onColorSelected: notifier.selectColor,
    );
  }

  void _showBrushOptions(BuildContext context) {
    final responsive = ResponsiveLayoutHelper(context);
    final maxHeight = MediaQuery.of(context).size.height * responsive.getBottomSheetMaxHeight();
    final fontSize = responsive.getFontSize(baseSize: 16);
    final iconSize = responsive.getIconSize(baseSize: 20);

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: CupertinoActionSheet(
              title: Text(
                'Select Brush Style',
                style: TextStyle(fontSize: fontSize + 2),
              ),
              actions:
                  BrushStyle.values.map((style) {
                    return CupertinoActionSheetAction(
                      onPressed: () {
                        notifier.selectBrushStyle(style);
                        Navigator.pop(context);
                        HapticFeedback.selectionClick();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getBrushIcon(style),
                            size: iconSize,
                          ),
                          SizedBox(width: responsive.isSmallScreen ? 6 : 8),
                          Flexible(
                            child: Text(
                              style.name,
                              style: TextStyle(fontSize: fontSize),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
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
    notifier.toggleMirrorMode();
    HapticFeedback.selectionClick();
  }
}
