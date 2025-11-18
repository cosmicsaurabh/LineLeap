import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:lineleap/presentation/features/queue/generating_queue_widget.dart';

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
                          provider.retryGeneration(request);
                          onTimerReset();
                        },
                        onDownload: (request) async {
                          onTimerCancel();
                          final success = await galleryNotifier.saveToHistory(
                            scribblePath: request.scribblePath,
                            generatedPath: request.generatedPath!,
                            prompt: request.prompt,
                            timestamp:
                                DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                          );
                          if (success) {
                            queueProvider.removeFromQueue(request);
                          }
                          if (isVisible) {
                            onTimerReset();
                          }
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
}
