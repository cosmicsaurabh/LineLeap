import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/widgets/generation_queue_item.dart';
import 'package:lineleap/presentation/features/gallery/gallery_image_dialog.dart';
import 'package:provider/provider.dart';

class GenerationQueueWidget extends StatelessWidget {
  const GenerationQueueWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueStatusProvider>(
      builder: (context, provider, child) {
        if (provider.queueItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.queue_play_next, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Generation Queue (${provider.queueItems.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: provider.refreshQueue,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: provider.queueItems.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = provider.queueItems[index];
                    return GenerationQueueItem(
                      request: request,
                      onRemove: () => provider.removeFromQueue(request),
                      onRetry: () => _retryGeneration(context, request),
                      onDownload:
                          request.generatedPath == null
                              ? () {}
                              : () => _saveHistory(context, request),
                      onView:
                          request.generatedPath == null
                              ? () {}
                              : () => _showImageDialog(
                                1,
                                context,
                                ScribbleTransformation(
                                  generatedImagePath: request.generatedPath!,
                                  scribbleImagePath: request.scribblePath,
                                  prompt: request.prompt,
                                  timestamp:
                                      request.createdAt?.toIso8601String() ??
                                      "-",
                                ),
                                Provider.of<GalleryNotifier>(
                                  context,
                                  listen: false,
                                ),
                              ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _retryGeneration(BuildContext context, GenerationRequest request) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Retrying generation...')));

    try {
      final queueProvider = Provider.of<QueueStatusProvider>(
        context,
        listen: false,
      );

      queueProvider.retryGeneration(request);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _saveHistory(BuildContext context, GenerationRequest request) async {
    try {
      final galleryNotifier = Provider.of<GalleryNotifier>(
        context,
        listen: false,
      );
      final queueProvider = Provider.of<QueueStatusProvider>(
        context,
        listen: false,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saving to History...')));

      // Save to history
      bool success = await galleryNotifier.saveToHistory(
        scribblePath: request.scribblePath,
        generatedPath: request.generatedPath!,
        prompt: request.prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      if (success) {
        queueProvider.removeFromQueue(request);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image saved to gallery'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _showImageDialog(
    int whichImage, // 0 for scribble, 1 for generated
    BuildContext context,
    ScribbleTransformation scribbleTransformation,
    GalleryNotifier gallery,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.1),
      builder:
          (context) => GalleryImageDialog(
            scribbleTransformation: scribbleTransformation,
            gallery: gallery,
            whichImage: whichImage,
          ),
    );
  }
}
