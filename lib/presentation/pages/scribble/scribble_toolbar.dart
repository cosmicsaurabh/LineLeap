// Scribble Toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_scribble/presentation/pages/scribble/scribble_page.dart';

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
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, child) {
        return Padding(
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
              const SizedBox(width: 16),
              _buildColorPicker(context),
              const SizedBox(width: 16),
              _buildBrushSelector(context),
              const Spacer(),
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

  Widget _buildColorPicker(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Row(
      children:
          colors.map((color) {
            final isSelected = notifier.state.selectedColor == color;
            return GestureDetector(
              onTap: () {
                notifier.selectColor(color);
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border:
                      isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                          : null,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildBrushSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showBrushOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
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
      case BrushStyle.dotted:
        return CupertinoIcons.circle_grid_3x3;
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
