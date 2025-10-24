import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/theme/app_theme.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/features/gallery/gallery_action_sheet.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/widgets/report_content_dialog.dart';

class GalleryImageDialog extends StatefulWidget {
  final int whichImage; // 0 for scribble, 1 for generated
  final ScribbleTransformation scribbleTransformation;
  final GalleryNotifier gallery;

  const GalleryImageDialog({
    super.key,
    required this.scribbleTransformation,
    required this.gallery,
    required this.whichImage,
  });

  @override
  State<GalleryImageDialog> createState() => _GalleryImageDialogState();
}

class _GalleryImageDialogState extends State<GalleryImageDialog>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  String? createdAt;

  String? imagePathForHero;
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Uint8List? _imageBytes;
  bool _isLoading = false;
  Future<void> _loadImage() async {
    if (_isLoading) return; // Prevent concurrent loading
    createdAt = widget.scribbleTransformation.timestamp;
    try {
      final timestamp = int.parse(widget.scribbleTransformation.timestamp);
      final date =
          DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
      createdAt = date;
    } catch (e) {
      createdAt = "-";
    }

    setState(() => _isLoading = true);

    try {
      // Determine which image we're working with
      final bool isScribble = widget.whichImage == 0;
      final imagePath =
          isScribble
              ? widget.scribbleTransformation.scribbleImagePath
              : widget.scribbleTransformation.generatedImagePath;
      setState(() {
        imagePathForHero = imagePath;
      });

      // Otherwise load from file
      final file = File(imagePath);
      if (!await file.exists()) {
        setState(() => _isLoading = false);
        if (!mounted) return;

        final errorMessage =
            isScribble
                ? 'Scribble image not found'
                : 'Generated image not found';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading image: $e')));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding16),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_imageBytes != null)
                _buildImageSection(
                  _imageBytes!,
                  context,
                  isDarkMode,
                  theme,
                  imagePathForHero,
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: AppTheme.spacing24),
                      Icon(
                        CupertinoIcons.photo,
                        size: 64,
                        color: isDarkMode ? Colors.white38 : Colors.black26,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      Text(
                        'Image not found',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'This image could not be loaded.',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white38 : Colors.black45,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacing24),
                    ],
                  ),
                ),
              const SizedBox(height: AppTheme.spacing16),
              _buildTimeStampSection(createdAt, context, isDarkMode),
              const SizedBox(height: AppTheme.spacing16),
              if (widget.scribbleTransformation.prompt.isNotEmpty)
                _buildPromptSection(theme, context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeStampSection(
    String? createdAt,
    BuildContext context,
    bool isDarkMode,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Created at: "),
        Text(
          createdAt ?? "-",
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(
    Uint8List image,
    BuildContext context,
    bool isDarkMode,
    ThemeData theme,
    String? imagePathForHero,
  ) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            child: InteractiveViewer(
              transformationController:
                  _transformationController, // Add this controller
              minScale: 1.0,
              maxScale: 10.0,
              panEnabled: true,
              onInteractionEnd: (ScaleEndDetails details) {
                setState(() {
                  _currentScale =
                      _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child: Hero(
                tag: 'image_$imagePathForHero',
                child: Image.memory(
                  image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
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
                icon: CupertinoIcons.flag,
                onPressed: () => _showReportDialog(context),
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
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
        Positioned(
          left: 8,
          bottom: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_currentScale != 1.0)
                _buildActionButton(
                  icon: Icons.refresh,
                  onPressed: () {
                    _transformationController.value = Matrix4.identity();
                    setState(() {
                      _currentScale = 1.0;
                    });
                  },
                  isDarkMode: isDarkMode,
                )
              else
                _buildActionButton(
                  icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                  onPressed: () {},
                  isDarkMode: isDarkMode,
                ),
              const SizedBox(height: 8),
              _buildNonActionButton(
                label: '${_currentScale.toStringAsFixed(1)}x',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: CupertinoIcons.add,
                onPressed: () {
                  if (_currentScale >= 10) {
                    setState(() {
                      _currentScale = 10;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maximum zoom in reached',
                          style: TextStyle(color: theme.colorScheme.onError),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                    return;
                  }
                  double nextScale = _currentScale * 1.5;
                  if (nextScale > 10) {
                    nextScale = 10;
                  }
                  double scaleFactor = nextScale / _currentScale;
                  _transformationController.value.scale(scaleFactor);
                  setState(() {
                    _currentScale = nextScale;
                  });
                },
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: CupertinoIcons.minus,
                onPressed: () {
                  if (_currentScale <= 1.0) {
                    setState(() {
                      _currentScale = 1.0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Maximum zoom out reached',
                          style: TextStyle(color: theme.colorScheme.onError),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                    return;
                  }
                  double nextScale = _currentScale * 0.75;
                  if (nextScale < 1) {
                    nextScale = 1;
                  }
                  double scaleFactor = nextScale / _currentScale;
                  _transformationController.value.scale(scaleFactor);
                  setState(() {
                    _currentScale = nextScale;
                  });
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? const Color.fromARGB(51, 159, 159, 213)
                    : const Color.fromARGB(111, 249, 249, 250),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color.fromARGB(51, 159, 159, 213)
                      : const Color.fromARGB(111, 249, 249, 250),
              width: 0.5,
            ),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            child: Icon(
              icon,
              size: 18,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNonActionButton({
    IconData? icon,
    required bool isDarkMode,
    String? label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? const Color.fromARGB(51, 159, 159, 213)
                    : const Color.fromARGB(111, 249, 249, 250),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode
                      ? CupertinoColors.systemGrey5.darkColor
                      : CupertinoColors.systemGrey5.color,
              width: 0.5,
            ),
          ),
          child: Center(
            child:
                label != null
                    ? Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            isDarkMode
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                      ),
                    )
                    : Icon(
                      icon,
                      size: 18,
                      color:
                          isDarkMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptSection(
    ThemeData theme,
    BuildContext context,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.systemBackground.color,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        // border: Border.all(
        //   color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            maxLines: 2,
            'Prompt',
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  isDarkMode
                      ? CupertinoColors.activeBlue.darkColor
                      : CupertinoColors.activeBlue.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), // iOS-style physics
              child: Text(
                widget.scribbleTransformation.prompt,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isDarkMode
                          ? CupertinoColors.label.darkColor
                          : CupertinoColors.label.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => GalleryActionSheet(
            image: widget.scribbleTransformation,
            gallery: widget.gallery,
            parentContext: this.context, // Pass the dialog's context
            onActionComplete: () {
              // Close the action sheet first
              Navigator.of(context).pop();
              // Then close the image dialog
              Navigator.of(context).pop();
            },
            index: widget.whichImage,
          ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final contentId =
        widget.whichImage == 0
            ? widget.scribbleTransformation.scribbleImagePath
            : widget.scribbleTransformation.generatedImagePath;
    final contentType = widget.whichImage == 0 ? 'scribble' : 'generated_image';

    showDialog(
      context: context,
      builder:
          (context) => ReportContentDialog(
            contentId: contentId,
            contentType: contentType,
          ),
    );
  }
}
