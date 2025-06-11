import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generated_image.dart';

class GalleryImageTile extends StatelessWidget {
  final GeneratedImage image;
  final VoidCallback onTap;

  const GalleryImageTile({super.key, required this.image, required this.onTap});

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
            child: Hero(
              tag: 'image_${image.generatedImagefilePath}',
              child: Image.file(
                File(image.generatedImagefilePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
