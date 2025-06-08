// Reusable Color Picker Dialog
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<void> showColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
  required ValueChanged<Color> onColorSelected,
}) async {
  Color pickedColor = initialColor;

  await showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onColorSelected(pickedColor);
                Navigator.of(context).pop();
              },
              child: const Text('Select'),
            ),
          ],
        ),
  );
}
