// iOS-Style Action Sheet
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';

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
