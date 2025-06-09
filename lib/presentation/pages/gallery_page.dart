import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:provider/provider.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();
    // Delay fetch to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryNotifier>().loadImages();
    });
  }

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
        return Stack(
          children: [
            GestureDetector(
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
                  ), // existing image view
              child: Image.file(File(image.filePath), fit: BoxFit.cover),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final shouldDelete = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Delete Image?'),
                            content: const Text(
                              'Are you sure you want to delete this image?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                    if (shouldDelete == true) {
                      await gallery.deleteImage(image);
                    }
                  }
                },
                itemBuilder:
                    (ctx) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
              ),
            ),
          ],
        );
      },
    );
  }
}
