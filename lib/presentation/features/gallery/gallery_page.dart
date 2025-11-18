import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/common/utils/responsive_layout_helper.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_tile.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';

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
    final theme = Theme.of(context);
    final responsive = ResponsiveLayoutHelper(context);
    final shouldUseVerticalAppBar = responsive.shouldUseVerticalAppBar();

    if (gallery.isLoading) {
      return Center(
        child: CupertinoActivityIndicator(
          radius: 16,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }

    if (gallery.scribbleTransformations.isEmpty) {
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
              "No scribbleTransformations found",
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
      appBar: shouldUseVerticalAppBar ? null : _buildAppBar(theme, isDarkMode),
      body: Row(
        children: [
          if (shouldUseVerticalAppBar) _buildVerticalAppBar(context, theme, isDarkMode),
          Expanded(
            child: _buildResponsiveGrid(gallery, isDarkMode),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    final responsive = ResponsiveLayoutHelper(context);
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            CupertinoIcons.scribble,
            color: theme.colorScheme.primary,
            size: responsive.getIconSize(baseSize: 28),
          ),
          if (MediaQuery.of(context).size.width > 360) const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width > 360)
            Text(
              'LineLeap',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: responsive.getFontSize(baseSize: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final responsive = ResponsiveLayoutHelper(context);
    return Container(
      width: responsive.isSmallScreen ? 56 : 72,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(
            CupertinoIcons.scribble,
            color: theme.colorScheme.primary,
            size: responsive.getIconSize(baseSize: 28),
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
          itemCount: gallery.scribbleTransformations.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            ScribbleTransformation image =
                gallery.scribbleTransformations[index];
            return _AnimatedGridItem(
              index: index,
              child: GalleryImageTile(
                image: image,
                onTap: () => _showImageDialog(1, context, image, gallery),
                onScribbleTap: () {
                  _showImageDialog(0, context, image, gallery);
                },
              ),
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
    ScribbleTransformation scribbleTransformation,
    GalleryNotifier gallery,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder:
          (context) => GalleryImageDialog(
            scribbleTransformation: scribbleTransformation,
            gallery: gallery,
            whichImage: whichImage,
          ),
    );
  }
}

class _AnimatedGridItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedGridItem({required this.index, required this.child});

  @override
  State<_AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<_AnimatedGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger animation based on index
    Future.delayed(
      Duration(milliseconds: (widget.index * 50).clamp(0, 500)),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
