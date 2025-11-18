import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';
import 'package:provider/provider.dart';

Widget buildThemeToggle(ThemeData theme, bool isDark, BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.2),
      ),
    ),
    child: IconButton(
      onPressed: () {
        context.read<ThemeNotifier>().setThemeMode(
          isDark ? ThemeMode.light : ThemeMode.dark,
        );
        HapticFeedback.selectionClick();
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDark ? CupertinoIcons.sun_max : CupertinoIcons.moon,
          key: ValueKey(isDark),
          color: theme.colorScheme.primary,
        ),
      ),
    ),
  );
}
