import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/core/theme/app_theme.dart';

Widget buildActionButton(
  BuildContext context, {
  String? label,
  required IconData icon,
  required VoidCallback onPressed,
  required bool isPrimary,
}) {
  final theme = Theme.of(context);

  return Container(
    decoration: BoxDecoration(
      gradient:
          isPrimary
              ? LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              )
              : null,
      color: isPrimary ? null : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      border:
          isPrimary
              ? null
              : Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isPrimary
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
              ),
              if (label != null) const SizedBox(width: 8),
              if (label != null)
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        isPrimary
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
