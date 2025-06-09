import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_scribble/presentation/pages/gallery/gallery_image_dialog.dart';
import 'package:flutter_scribble/presentation/pages/gallery/gallery_image_tile.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryNotifier>().loadImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryNotifier>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (gallery.isLoading) {
      return Center(
        child: CupertinoActivityIndicator(
          radius: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }

    if (gallery.images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 64,
              color: isDarkMode ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              "No images found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return _buildResponsiveGrid(gallery, isDarkMode);
  }

  Widget _buildResponsiveGrid(GalleryNotifier gallery, bool isDarkMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: gallery.images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final image = gallery.images[index];
            return GalleryImageTile(
              image: image,
              onTap: () => _showImageDialog(context, image, gallery),
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }

  void _showImageDialog(
    BuildContext context,
    dynamic image,
    GalleryNotifier gallery,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder: (context) => GalleryImageDialog(image: image, gallery: gallery),
    );
  }
}
