import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/core/theme/app_theme.dart';
import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/presentation/pages/gallery/gallery_action_sheet.dart';
import 'package:lineleap/presentation/widgets/providers/gallery_notifier.dart';

class GalleryImageDialog extends StatefulWidget {
  final GeneratedImage image;
  final GalleryNotifier gallery;

  const GalleryImageDialog({
    super.key,
    required this.image,
    required this.gallery,
  });

  @override
  State<GalleryImageDialog> createState() => _GalleryImageDialogState();
}

class _GalleryImageDialogState extends State<GalleryImageDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Uint8List? _imageBytes;
  bool _isLoading = false;
  _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(widget.image.generatedImagefilePath);
      final bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading image: $e')));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.85;
    final maxWidth = dialogWidth > 400 ? 400.0 : dialogWidth;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: maxWidth,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_imageBytes != null)
                              _buildImageSection(
                                _imageBytes!,
                                context,
                                isDarkMode,
                                theme,
                              )
                            else
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 32),
                                    Icon(
                                      CupertinoIcons.photo,
                                      size: 64,
                                      color:
                                          isDarkMode
                                              ? Colors.white38
                                              : Colors.black26,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Image not found',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white70
                                                : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'This image could not be loaded.',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? Colors.white38
                                                : Colors.black45,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            if (widget.image.prompt.isNotEmpty)
                              _buildPromptSection(theme, context, isDarkMode),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection(
    Uint8List image,
    BuildContext context,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            child: InteractiveViewer(
              transformationController:
                  _transformationController, // Add this controller
              minScale: 1.0,
              maxScale: 10.0,
              panEnabled: true,
              onInteractionEnd: (ScaleEndDetails details) {
                setState(() {
                  _currentScale =
                      _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Hero(
                tag: 'image_${widget.image.generatedImagefilePath}',
                child: Image.memory(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: CupertinoIcons.ellipsis,
                  onPressed: () => _showActionMenu(context),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: CupertinoIcons.xmark,
                  onPressed: () => Navigator.of(context).pop(),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNonActionButton(
                  label: '${_currentScale.toStringAsFixed(1)}x',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                if (_currentScale != 1.0)
                  _buildActionButton(
                    icon: Icons.refresh,
                    onPressed: () {
                      _transformationController.value = Matrix4.identity();
                      setState(() {
                        _currentScale = 1.0;
                      });
                    },
                    isDarkMode: isDarkMode,
                  )
                else
                  _buildActionButton(
                    icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                    onPressed: () {},
                    isDarkMode: isDarkMode,
                  ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: CupertinoIcons.add,
                  onPressed: () {
                    if (_currentScale >= 10) {
                      setState(() {
                        _currentScale = 10;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Maximum zoom in reached',
                            style: TextStyle(color: theme.colorScheme.onError),
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
                    _transformationController.value.scale(scaleFactor);
                    setState(() {
                      _currentScale = nextScale;
                    });
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: CupertinoIcons.minus,
                  onPressed: () {
                    if (_currentScale <= 1.0) {
                      setState(() {
                        _currentScale = 1.0;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Maximum zoom out reached',
                            style: TextStyle(color: theme.colorScheme.onError),
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
                    _transformationController.value.scale(scaleFactor);
                    setState(() {
                      _currentScale = nextScale;
                    });
                  },
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 18,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNonActionButton({
    IconData? icon,
    required bool isDarkMode,
    String? label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 18,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptSection(
    ThemeData theme,
    BuildContext context,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
                widget.image.prompt,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => GalleryActionSheet(
            image: widget.image,
            gallery: widget.gallery,
            parentContext: this.context, // Pass the dialog's context
            onActionComplete: () {
              // Close the action sheet first
              Navigator.of(context).pop();
              // Then close the image dialog
              Navigator.of(context).pop();
            },
          ),
    );
  }
}
