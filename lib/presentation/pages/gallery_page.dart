import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryNotifier>();

    if (gallery.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gallery.images.isEmpty) {
      return const Center(child: Text("No images found"));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: gallery.images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final image = gallery.images[index];
        return GestureDetector(
          onTap:
              () => showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.file(File(image.filePath)),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(image.prompt),
                          ),
                        ],
                      ),
                    ),
              ),
          child: Image.file(File(image.filePath), fit: BoxFit.cover),
        );
      },
    );
  }
}
