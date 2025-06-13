// Scribble Toolbar
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';
import 'package:lineleap/presentation/features/queue/queue_screen.dart';
import 'package:lineleap/presentation/features/scribble/scribble_page.dart';
import 'package:lineleap/presentation/common/dialogs/color_picker_dialog.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';

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
                ActionButton(
                  icon: CupertinoIcons.square_list,
                  label: 'Queue',
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QueueScreen(),
                        ),
                      ),
                  style: ActionButtonStyle.primary,
                ),
                SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.arrow_uturn_left,
                  onPressed: notifier.canUndo ? notifier.undo : () {},
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.arrow_uturn_right,
                  onPressed: notifier.canRedo ? notifier.redo : () {},
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
                // const SizedBox(width: 8),
                // ActionButton(
                //   onPressed: onModelSelect,
                //   icon: CupertinoIcons.square_list,
                //   label: 'Models',
                //   style: ActionButtonStyle.primary,
                // ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.textformat,
                  onPressed: onPrompt,
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.color_filter,
                  onPressed:
                      () => showColorPickerDialog(
                        context: context,
                        initialColor: notifier.state.selectedColor,
                        onColorSelected: notifier.selectColor,
                      ),
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),

                const SizedBox(width: 8),
                ActionButton(
                  onPressed: () {
                    _showBrushOptions(context);
                  },
                  icon: _getBrushIcon(notifier.state.brushStyle),

                  style: ActionButtonStyle.secondary,
                  label: notifier.state.brushStyle.name,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.clear,
                  onPressed: notifier.clear,
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
              ],
            ),
          ),
        );
      },
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
