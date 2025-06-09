import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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

// Reusable Image Tile Component
class GalleryImageTile extends StatelessWidget {
  final dynamic image;
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
              tag: 'image_${image.filePath}',
              child: Image.file(
                File(image.filePath),
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

// Glass Morphism Image Dialog
class GalleryImageDialog extends StatefulWidget {
  final dynamic image;
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

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                            _buildImageSection(context, isDarkMode),
                            _buildPromptSection(context, isDarkMode),
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

  Widget _buildImageSection(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'image_${widget.image.filePath}',
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Image.file(
                  File(widget.image.filePath),
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

  Widget _buildPromptSection(BuildContext context, bool isDarkMode) {
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
      child: Text(
        widget.image.prompt ?? "No prompt available",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white70 : Colors.black87,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
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

// iOS-Style Action Sheet
class GalleryActionSheet extends StatelessWidget {
  final dynamic image;
  final GalleryNotifier gallery;
  final BuildContext parentContext;
  final VoidCallback onActionComplete;

  const GalleryActionSheet({
    super.key,
    required this.image,
    required this.gallery,
    required this.parentContext,
    required this.onActionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CupertinoActionSheet(
      actions: [
        _buildActionTile(
          context: context,
          icon: CupertinoIcons.cloud_download,
          title: 'Download',
          onPressed: () => _handleDownload(context),
          isDarkMode: isDarkMode,
        ),
        _buildActionTile(
          context: context,
          icon: CupertinoIcons.share,
          title: 'Share',
          onPressed: () => _handleShare(context),
          isDarkMode: isDarkMode,
        ),
        _buildActionTile(
          context: context,
          icon: CupertinoIcons.pencil_circle,
          title: 'Scribble',
          onPressed: () => _handleScribble(context),
          isDarkMode: isDarkMode,
        ),
        _buildActionTile(
          context: context,
          icon: CupertinoIcons.delete,
          title: 'Delete',
          onPressed: () => _handleDelete(context),
          isDarkMode: isDarkMode,
          isDestructive: true,
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text('Cancel'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isDestructive = false,
  }) {
    return CupertinoActionSheetAction(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isDestructive
                    ? CupertinoColors.destructiveRed
                    : (isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.black),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  isDestructive
                      ? CupertinoColors.destructiveRed
                      : (isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDownload(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      final file = File(image.filePath);
      final Uint8List bytes = await file.readAsBytes();

      // Save to gallery
      _showNonInteractiveActionFeedback(context, 'Download started');
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: "scribble_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result['isSuccess'] == true || result['filePath'] != null) {
        _showInteractiveActionFeedback(context, 'Image saved to gallery!');
      } else {
        _showNonInteractiveActionFeedback(context, 'Failed to save image.');
      }
    } catch (e) {
      _showNonInteractiveActionFeedback(context, 'Something went wrong');
    }
  }

  void _handleShare(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      final file = File(image.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              image.prompt ?? 'Check out my AI-generated image from scribble!',
        );
      } else {
        _showNonInteractiveActionFeedback(parentContext, 'File not found');
      }
    } catch (e) {
      _showNonInteractiveActionFeedback(parentContext, 'Failed to share image');
    }
  }

  void _handleScribble(BuildContext context) {
    Navigator.of(context).pop();
    onActionComplete();
    // TODO: Navigate to scribble editor
    _showNonInteractiveActionFeedback(context, 'Opening Scribble editor');
  }

  void _handleDelete(BuildContext context) async {
    final navigator = Navigator.of(context);

    navigator.pop();
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Image'),
            content: const Text(
              'Are you sure you want to delete this image? This action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      navigator.pop();
      try {
        gallery.deleteImage(image);
        _showNonInteractiveActionFeedback(context, 'Image deleted');
      } catch (e) {
        log('Failed to delete image: $e');
        _showNonInteractiveActionFeedback(context, 'Failed to delete image');
      }
    }
  }

  void _showInteractiveActionFeedback(BuildContext context, String message) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            message: Text(message),
            cancelButton: CupertinoActionSheetAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _showNonInteractiveActionFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }
}
