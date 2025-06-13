import 'package:flutter/material.dart';
import 'package:lineleap/presentation/common/dialogs/color_picker_dialog.dart';
import 'package:lineleap/presentation/common/widgets/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/widgets/toolbar/toolbar_icon_button.dart';

class ScribbleeToolbar extends StatelessWidget {
  final EnhancedScribbleNotifier notifier;
  final VoidCallback onPrompt;
  final VoidCallback onClear;

  const ScribbleeToolbar({
    super.key,
    required this.notifier,
    required this.onPrompt,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Text prompt button
        ElevatedButton(
          onPressed: onPrompt,
          child: const Icon(Icons.text_fields, size: 28),
        ),

        // Clear button
        ElevatedButton(
          onPressed: onClear,
          child: const Icon(Icons.clear, size: 28),
        ),

        // Color picker button
        ElevatedButton(
          child: Icon(Icons.color_lens, color: notifier.state.selectedColor),
          onPressed:
              () => showColorPickerDialog(
                context: context,
                initialColor: notifier.state.selectedColor,
                onColorSelected: notifier.selectColor,
              ),
        ),

        // Undo button
        ToolbarIconButton(
          tooltip: "Undo",
          icon: Icons.undo,
          isActive: notifier.canUndo,
          onPressed: () {
            if (notifier.canUndo) {
              notifier.undo();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Nothing to undo"),
                  duration: Duration(milliseconds: 150),
                ),
              );
            }
          },
        ),

        // Redo button
        ToolbarIconButton(
          tooltip: "Redo",
          icon: Icons.redo,
          isActive: notifier.canRedo,
          onPressed: () {
            if (notifier.canRedo) {
              notifier.redo();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Nothing to redo"),
                  duration: Duration(milliseconds: 150),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
