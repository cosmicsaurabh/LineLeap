import 'dart:math';

import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ColorPicker({super.key, required this.onColorSelected});

  @override
  Widget build(BuildContext context) {
    final outerColors = [
      Colors.black,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.brown,
    ];

    final innerColors = [
      Colors.pink.shade100,
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.yellow.shade100,
    ];

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...List.generate(outerColors.length, (i) {
            final angle = (i / outerColors.length) * 2 * 3.14159;
            return Positioned(
              left: 80 + 65 * (1 + 0.1) * (0.5 + 0.5 * cos(angle)),
              top: 80 + 65 * (1 + 0.1) * (0.5 + 0.5 * sin(angle)),
              child: GestureDetector(
                onTap: () => onColorSelected(outerColors[i]),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: outerColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            );
          }),
          ...List.generate(innerColors.length, (i) {
            final angle = (i / innerColors.length) * 2 * 3.14159;
            return Positioned(
              left: 80 + 40 * (1 + 0.1) * (0.5 + 0.5 * cos(angle)),
              top: 80 + 40 * (1 + 0.1) * (0.5 + 0.5 * sin(angle)),
              child: GestureDetector(
                onTap: () => onColorSelected(innerColors[i]),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: innerColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () async {
              final color = await showDialog<Color>(
                context: context,
                builder: (context) => _CustomColorDialog(),
              );
              if (color != null) onColorSelected(color);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  double r = 0, g = 0, b = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick Custom Color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: r,
            min: 0,
            max: 255,
            label: 'R: ${r.round()}',
            onChanged: (v) => setState(() => r = v),
            activeColor: Colors.red,
          ),
          Slider(
            value: g,
            min: 0,
            max: 255,
            label: 'G: ${g.round()}',
            onChanged: (v) => setState(() => g = v),
            activeColor: Colors.green,
          ),
          Slider(
            value: b,
            min: 0,
            max: 255,
            label: 'B: ${b.round()}',
            onChanged: (v) => setState(() => b = v),
            activeColor: Colors.blue,
          ),
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, r.round(), g.round(), b.round()),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed:
              () => Navigator.pop(
                context,
                Color.fromARGB(255, r.round(), g.round(), b.round()),
              ),
          child: const Text('Select'),
        ),
      ],
    );
  }
}
