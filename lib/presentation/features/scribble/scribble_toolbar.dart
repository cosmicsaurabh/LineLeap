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
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                // ActionButton(
                //   icon: CupertinoIcons.square_list,
                //   label: 'Queue',
                //   onPressed:
                //       () => Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const QueueScreen(),
                //         ),
                //       ),
                //   style: ActionButtonStyle.primary,
                // ),
                SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.arrow_uturn_left,
                  onPressed: widget.notifier.canUndo ? widget.notifier.undo : () {},
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.arrow_uturn_right,
                  onPressed: widget.notifier.canRedo ? widget.notifier.redo : () {},
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
                  onPressed: widget.onPrompt,
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.color_filter,
                  onPressed:
                      () => showColorPickerDialog(
                        context: context,
                        initialColor: widget.notifier.state.selectedColor,
                        onColorSelected: widget.notifier.selectColor,
                      ),
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),

                const SizedBox(width: 8),
                ActionButton(
                  onPressed: () {
                    _showBrushOptions(context);
                  },
                  icon: _getBrushIcon(widget.notifier.state.brushStyle),

                  style: ActionButtonStyle.secondary,
                  tooltip: widget.notifier.state.brushStyle.name,
                  showBorder: false,
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: CupertinoIcons.clear,
                  onPressed: widget.notifier.clear,
                  style: ActionButtonStyle.secondary,
                  showBorder: false,
                ),
              ],
              ),
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
