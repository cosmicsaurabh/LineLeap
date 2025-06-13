import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ActionButtonStyle { primary, secondary, destructive }

class ActionButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onPressed;
  final ActionButtonStyle style;
  final bool showBorder;

  const ActionButton({
    super.key,
    this.icon,
    this.label,
    required this.onPressed,
    this.style = ActionButtonStyle.primary,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on style
    Color textColor;
    Color bgColor;

    switch (style) {
      case ActionButtonStyle.primary:
        textColor = theme.colorScheme.onPrimary;
        bgColor = theme.colorScheme.primary;
        break;
      case ActionButtonStyle.destructive:
        textColor = CupertinoColors.white;
        bgColor = CupertinoColors.destructiveRed;
        break;
      default:
        textColor = isDarkMode ? CupertinoColors.white : CupertinoColors.black;
        bgColor =
            isDarkMode
                ? const Color.fromARGB(51, 159, 159, 213)
                : const Color.fromARGB(111, 249, 249, 250);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border:
                showBorder
                    ? Border.all(
                      color:
                          isDarkMode
                              ? CupertinoColors.systemGrey5.darkColor
                              : CupertinoColors.systemGrey5.color,
                      width: 0.5,
                    )
                    : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: textColor, size: 18),
              if (icon != null && label != null) const SizedBox(width: 8),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
