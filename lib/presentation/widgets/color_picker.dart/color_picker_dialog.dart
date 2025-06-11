import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<void> showColorPickerDialog({
  required BuildContext context,
  required Color initialColor,
  required ValueChanged<Color> onColorSelected,
}) async {
  await showCupertinoDialog(
    context: context,
    builder:
        (context) => _GlassColorPickerDialog(
          initialColor: initialColor,
          onColorSelected: onColorSelected,
        ),
  );
}

class _GlassColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  const _GlassColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_GlassColorPickerDialog> createState() =>
      _GlassColorPickerDialogState();
}

class _GlassColorPickerDialogState extends State<_GlassColorPickerDialog> {
  late Color pickedColor;

  @override
  void initState() {
    super.initState();
    pickedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: CupertinoAlertDialog(
        title: const Text('Select Color'),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Material(
            color: Colors.transparent,
            child: ColorPicker(
              pickerColor: pickedColor,
              onColorChanged: (color) {
                setState(() => pickedColor = color);
              },
              enableAlpha: true,
              displayThumbColor: true,
              pickerAreaHeightPercent: 1,
              colorPickerWidth: 240,
              pickerAreaBorderRadius: BorderRadius.circular(12),
              paletteType: PaletteType.hueWheel,
              labelTypes: [
                ColorLabelType.rgb,
                ColorLabelType.hsl,
                ColorLabelType.hex,
              ],
              hexInputBar: true,
              portraitOnly: true,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Select'),
            onPressed: () {
              widget.onColorSelected(pickedColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
