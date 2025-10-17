import 'package:flutter/material.dart';

class ThemeToggle extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const ThemeToggle({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
