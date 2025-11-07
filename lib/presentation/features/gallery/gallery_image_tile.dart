// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';

class GalleryImageTile extends StatefulWidget {
  final ScribbleTransformation image;
  final VoidCallback onTap;
  final VoidCallback onScribbleTap;

  const GalleryImageTile({
    super.key,
    required this.image,
    required this.onTap,
    required this.onScribbleTap,
  });

  @override
  State<GalleryImageTile> createState() => _GalleryImageTileState();
}

class _GalleryImageTileState extends State<GalleryImageTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerEnter() {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onPointerExit() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => _onPointerEnter(),
        onExit: (_) => _onPointerExit(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(_isHovered ? 0.5 : 0.3)
                            : Colors.black.withOpacity(
                                _isHovered ? 0.15 : 0.08),
                        blurRadius: _isHovered ? 20 : 12,
                        offset: Offset(0, _isHovered ? 8 : 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Main generated image
                        Opacity(
                          opacity: _opacityAnimation.value,
                          child: _buildImageWidget(widget.image.generatedImagePath),
                        ),

                        // Scribble preview in corner with its own tap handler
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: GestureDetector(
                            onTap: () {
                              widget.onScribbleTap();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isHovered ? 70 : 60,
                              height: _isHovered ? 70 : 60,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.black.withOpacity(0.65)
                                    : Colors.white.withOpacity(0.65),
                                backgroundBlendMode: BlendMode.luminosity,
                                border: Border.all(
                                  color: Colors.white,
                                  width: _isHovered ? 3 : 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _isHovered
                                    ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImageWidget(
                                    widget.image.scribbleImagePath),
                              ),
                            ),
                          ),
                        ),

                        // Optional label for clarity
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: _isHovered ? 12 : 8,
                              vertical: _isHovered ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              CupertinoIcons.sparkles,
                              color: Colors.white,
                              size: _isHovered ? 14 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String filePath) {
    // Otherwise load from file
    return Hero(
      tag: 'generated_image_${filePath}',
      child: Image.file(
        File(filePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(CupertinoIcons.photo_fill_on_rectangle_fill),
          );
        },
      ),
    );
  }
}
