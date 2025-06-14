// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';

class GalleryImageTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Main generated image
                _buildImageWidget(image.generatedImagePath),

                // Scribble preview in corner with its own tap handler
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: GestureDetector(
                    onTap: () {
                      onScribbleTap();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.65)
                                : Colors.white.withOpacity(0.65),
                        // Glass effect
                        backgroundBlendMode: BlendMode.luminosity,
                        // Optionally, add a subtle blur using BackdropFilter outside this BoxDecoration if needed
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildImageWidget(image.scribbleImagePath),
                      ),
                    ),
                  ),
                ),

                // Optional label for clarity
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      color: Colors.white,
                      size: 12,
                    ),
                    // child: const Text(
                    //   'Generated',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 10,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                  ),
                ),
              ],
            ),
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
