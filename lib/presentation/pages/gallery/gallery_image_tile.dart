import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generated_image.dart';

class GalleryImageTile extends StatelessWidget {
  final GeneratedImage image;
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
                Hero(
                  tag: 'generated_image_${image.generatedImageFilePath}',
                  child: Image.file(
                    File(image.generatedImageFilePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

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
                        child: Hero(
                          tag: 'scribble_image_${image.scribbleImageFilePath}',
                          child: Image.file(
                            File(image.scribbleImageFilePath),
                            fit: BoxFit.cover,
                          ),
                        ),
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
}
