// File: lib/presentation/widgets/color_picker.dart

import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ColorPicker({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            colors
                .map(
                  (color) => GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
