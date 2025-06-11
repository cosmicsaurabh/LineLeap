// Scribble Toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/pages/scribble/scribble_page.dart';
import 'package:lineleap/presentation/widgets/color_picker.dart/color_picker_dialog.dart';
import 'package:lineleap/presentation/widgets/providers/scribble_notifier.dart';

class ScribbleToolbar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildToolButton(
                  context,
                  icon: CupertinoIcons.arrow_uturn_left,
                  onPressed: notifier.canUndo ? notifier.undo : null,
                ),
                const SizedBox(width: 8),
                _buildToolButton(
                  context,
                  icon: CupertinoIcons.arrow_uturn_right,
                  onPressed: notifier.canRedo ? notifier.redo : null,
                ),
                const SizedBox(width: 8),
                _buildToolButton(
                  context,
                  color: notifier.state.selectedColor,
                  icon: Icons.palette,
                  onPressed:
                      () => showColorPickerDialog(
                        context: context,
                        initialColor: notifier.state.selectedColor,
                        onColorSelected: notifier.selectColor,
                      ),
                ),
                const SizedBox(width: 8),
                _buildBrushSelector(context),
                const SizedBox(width: 8),
                _buildToolButton(
                  context,
                  icon: CupertinoIcons.textformat,
                  onPressed: onPrompt,
                ),
                const SizedBox(width: 8),
                _buildToolButton(
                  context,
                  icon: CupertinoIcons.clear,
                  onPressed: notifier.clear,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isEnabled
                    ? (color ?? theme.colorScheme.primary).withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color:
                isEnabled
                    ? (color ?? theme.colorScheme.primary)
                    : theme.colorScheme.outline,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildBrushSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBrushOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getBrushIcon(notifier.state.brushStyle),
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              notifier.state.brushStyle.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
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
                      notifier.selectBrushStyle(style);
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
