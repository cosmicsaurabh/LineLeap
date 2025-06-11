import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineleap/core/theme/app_theme.dart';
import 'package:lineleap/presentation/widgets/toolbar/action_button.dart';

class GeneratedImageViewer extends StatefulWidget {
  final Uint8List image;
  final String prompt;

  const GeneratedImageViewer({
    super.key,
    required this.image,
    required this.prompt,
  });

  @override
  State<GeneratedImageViewer> createState() => _GeneratedImageViewerState();
}

class _GeneratedImageViewerState extends State<GeneratedImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  void _shareImage(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would be implemented here'),
      ),
    );
  }

  void _saveImage(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Image saved to gallery'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: (isDark
                      ? const Color.fromARGB(255, 30, 7, 7)
                      : Colors.white)
                  .withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Generated Image',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),

                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.xmark_circle_fill),
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                ),

                // Image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                        child: InteractiveViewer(
                          transformationController:
                              _transformationController, // Add this controller
                          minScale: 1.0,
                          maxScale: 10.0,
                          panEnabled: true,
                          child: Image.memory(
                            widget.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                          onInteractionEnd: (details) {
                            setState(() {
                              _currentScale =
                                  _transformationController.value
                                      .getMaxScaleOnAxis();
                            });
                          },
                        ),
                      ),

                      // Zoom controls toolbar (top right)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            if (_currentScale != 1.0)
                              GestureDetector(
                                onTap: () {
                                  _transformationController.value =
                                      Matrix4.identity();
                                  setState(() {
                                    _currentScale = 1.0;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  CupertinoIcons.arrow_up_left_arrow_down_right,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            SizedBox(width: 8),
                            // Zoom in button
                            GestureDetector(
                              onTap: () {
                                if (_currentScale >= 10) {
                                  setState(() {
                                    _currentScale = 10;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Maximum zoom in reached',
                                        style: TextStyle(
                                          color: theme.colorScheme.onError,
                                        ),
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                  return;
                                }
                                double nextScale = _currentScale * 1.5;
                                if (nextScale > 10) {
                                  nextScale = 10;
                                }
                                double scaleFactor = nextScale / _currentScale;
                                _transformationController.value.scale(
                                  scaleFactor,
                                );
                                setState(() {
                                  _currentScale = nextScale;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  CupertinoIcons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Zoom out button
                            GestureDetector(
                              onTap: () {
                                if (_currentScale <= 1) {
                                  setState(() {
                                    _currentScale = 1;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Maximum zoom out reached',
                                        style: TextStyle(
                                          color: theme.colorScheme.onError,
                                        ),
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                  );
                                  return;
                                }
                                double nextScale = _currentScale * 0.75;
                                if (nextScale < 1) {
                                  nextScale = 1;
                                }
                                double scaleFactor = nextScale / _currentScale;
                                _transformationController.value.scale(
                                  scaleFactor,
                                );
                                setState(() {
                                  _currentScale = nextScale;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  CupertinoIcons.minus,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scale indicator (bottom left)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_currentScale.toStringAsFixed(1)}x',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Prompt
                if (widget.prompt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prompt',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 120, // ~5-6 lines
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                widget.prompt,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final showLabel = constraints.maxWidth > 100;
                            return buildActionButton(
                              context,
                              label: showLabel ? 'Share' : null,
                              icon: CupertinoIcons.share,
                              onPressed: () => _shareImage(context),
                              isPrimary: false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final showLabel = constraints.maxWidth > 100;
                            return buildActionButton(
                              context,
                              label: showLabel ? 'Save' : null,
                              icon: CupertinoIcons.download_circle,
                              onPressed: () => _saveImage(context),
                              isPrimary: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
