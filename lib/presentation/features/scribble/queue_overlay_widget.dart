import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:lineleap/presentation/features/queue/generating_queue_widget.dart';
import 'package:provider/provider.dart';

class QueueOverlayWidget extends StatelessWidget {
  final bool isVisible;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onTimerReset;
  final VoidCallback onTimerCancel;

  const QueueOverlayWidget({
    super.key,
    required this.isVisible,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onTimerReset,
    required this.onTimerCancel,
  });

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueStatusProvider>(
      context,
      listen: false,
    );
    final galleryNotifier = Provider.of<GalleryNotifier>(
      context,
      listen: false,
    );

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child:
          isVisible
              ? GestureDetector(
                onTap: onTimerReset,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Consumer<QueueStatusProvider>(
                    builder: (context, provider, child) {
                      return GenerationQueueWidget(
                        onExpansionChanged: (expanded) {
                          onExpansionChanged(expanded);
                        },
                        queueItems: provider.queueItems,
                        refreshQueue: provider.refreshQueue,
                        onRemove: (request) {
                          provider.removeFromQueue(request);
                          onTimerReset();
                        },
                        onRetry: (request) {
                          _retryGeneration(context, provider, request);
                        },
                        onDownload: (request) async {
                          await _saveToHistory(
                            context,
                            queueProvider,
                            galleryNotifier,
                            request,
                          );
                        },
                        onView: (request) {
                          onTimerCancel();
                          showDialog(
                            context: context,
                            barrierColor: Colors.black.withValues(alpha: 0.1),
                            builder:
                                (context) => GalleryImageDialog(
                                  scribbleTransformation:
                                      ScribbleTransformation(
                                        generatedImagePath:
                                            request.generatedPath!,
                                        scribbleImagePath: request.scribblePath,
                                        prompt: request.prompt,
                                        timestamp:
                                            request.createdAt
                                                ?.toIso8601String() ??
                                            "-",
                                      ),
                                  gallery: galleryNotifier,
                                  whichImage: 0,
                                ),
                          ).then((_) {
                            if (isVisible) {
                              onTimerReset();
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  Future<void> _retryGeneration(
    BuildContext context,
    QueueStatusProvider provider,
    GenerationRequest request,
  ) async {
    final failureMessage = await provider.retryGeneration(request);
    if (!context.mounted) return;

    if (failureMessage != null) {
      _showRetryableSnackBar(
        context,
        message: failureMessage,
        onRetry: () => _retryGeneration(context, provider, request),
      );
    }
    if (isVisible) {
      onTimerReset();
    }
  }

  Future<void> _saveToHistory(
    BuildContext context,
    QueueStatusProvider queueProvider,
    GalleryNotifier galleryNotifier,
    GenerationRequest request,
  ) async {
    final generatedPath = request.generatedPath;
    if (generatedPath == null || generatedPath.isEmpty) {
      _showRetryableSnackBar(
        context,
        message:
            'Couldn’t add this image to History because the generated file '
            'is missing.',
        onRetry:
            () => _saveToHistory(
              context,
              queueProvider,
              galleryNotifier,
              request,
            ),
      );
      return;
    }

    onTimerCancel();
    final success = await galleryNotifier.saveToHistory(
      scribblePath: request.scribblePath,
      generatedPath: generatedPath,
      prompt: request.prompt,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    if (!context.mounted) return;

    if (success) {
      await queueProvider.removeFromQueue(request);
    } else {
      _showRetryableSnackBar(
        context,
        message:
            galleryNotifier.operationError ??
            'Couldn’t add this image to History. It’s still in the queue—try '
                'again.',
        onRetry:
            () => _saveToHistory(
              context,
              queueProvider,
              galleryNotifier,
              request,
            ),
      );
    }

    if (isVisible) {
      onTimerReset();
    }
  }

  void _showRetryableSnackBar(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(label: 'Try again', onPressed: onRetry),
        ),
      );
  }
}
