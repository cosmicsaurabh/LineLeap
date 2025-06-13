import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_tile.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
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

    return Scaffold(
      appBar: _buildAppBar(Theme.of(context), isDarkMode),
      body: _buildResponsiveGrid(gallery, isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            CupertinoIcons.scribble,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          if (MediaQuery.of(context).size.width > 360) const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width > 360)
            Text(
              'LineLeap',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
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
            GeneratedImage image = gallery.images[index];
            return GalleryImageTile(
              image: image,
              onTap: () => _showImageDialog(1, context, image, gallery),
              onScribbleTap: () {
                _showImageDialog(0, context, image, gallery);
              },
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
    int whichImage, // 0 for scribble, 1 for generated
    BuildContext context,
    GeneratedImage image,
    GalleryNotifier gallery,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder:
          (context) => GalleryImageDialog(
            image: image,
            gallery: gallery,
            whichImage: whichImage,
          ),
    );
  }
}
