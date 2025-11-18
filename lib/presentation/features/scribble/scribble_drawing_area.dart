import 'package:flutter/material.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/features/scribble/drawing_canvas.dart';
import 'package:lineleap/theme/app_theme.dart';

class ScribbleDrawingArea extends StatelessWidget {
  final EnhancedScribbleNotifier notifier;
  final GlobalKey paintKey;
  final ThemeData theme;
  final bool isDark;

  const ScribbleDrawingArea({
    super.key,
    required this.notifier,
    required this.paintKey,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: RepaintBoundary(
            key: paintKey,
            child: DrawingCanvas(notifier: notifier),
          ),
        ),
      ),
    );
  }
}
