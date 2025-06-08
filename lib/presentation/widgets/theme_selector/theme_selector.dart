import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_notifier.dart';
import 'theme_toggle.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemeToggle(
            icon: Icons.wb_sunny,
            tooltip: "Light",
            isSelected: themeNotifier.themeMode == ThemeMode.light,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
          ),
          ThemeToggle(
            icon: Icons.phone_android,
            tooltip: "System",
            isSelected: themeNotifier.themeMode == ThemeMode.system,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
          ),
          ThemeToggle(
            icon: Icons.nightlight_round,
            tooltip: "Dark",
            isSelected: themeNotifier.themeMode == ThemeMode.dark,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}
