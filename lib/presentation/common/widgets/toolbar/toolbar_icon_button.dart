// Reusable Icon Button with Tooltip
import 'package:flutter/material.dart';

class ToolbarIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final double size;

  const ToolbarIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.isActive = true,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              icon,
              size: size,
              color:
                  isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
