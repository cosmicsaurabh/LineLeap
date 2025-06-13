import 'package:flutter/material.dart';
import 'package:lineleap/presentation/widgets/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/widgets/providers/queue_status_provider.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/generation_request.dart';

class QueueStatusList extends StatelessWidget {
  const QueueStatusList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QueueStatusProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.queueItems.isEmpty) {
          return const Center(child: Text('No items in queue'));
        }

        return RefreshIndicator(
          onRefresh: provider.refreshQueue,
          child: ListView.builder(
            itemCount: provider.queueItems.length,
            itemBuilder: (context, index) {
              final item = provider.queueItems[index];
              return _QueueItemTile(item: item);
            },
          ),
        );
      },
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  final GenerationRequest item;

  const _QueueItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _buildStatusIcon(),
        title: Text(item.prompt, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Status: ${_getStatusText()}'),
        trailing: _buildTrailingWidget(context),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (item.status) {
      case GenerationStatus.queued:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case GenerationStatus.submitting:
      case GenerationStatus.polling:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case GenerationStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case GenerationStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      // default:
      //   return const Icon(Icons.help_outline);
    }
  }

  String _getStatusText() {
    switch (item.status) {
      case GenerationStatus.queued:
        return 'Waiting';
      case GenerationStatus.submitting:
        return 'Submitting';
      case GenerationStatus.polling:
        return 'Polling';
      case GenerationStatus.completed:
        return 'Completed';
      case GenerationStatus.failed:
        return 'Failed';
    }
  }

  Widget _buildTrailingWidget(BuildContext context) {
    if (item.status == GenerationStatus.completed &&
        item.generatedPath != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: () {
              // Add logic to download the generated image
              _saveToGallery(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              // Add logic to view the generated image
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      final galleryNotifier = Provider.of<GalleryNotifier>(
        context,
        listen: false,
      );

      // Save to gallery
      await galleryNotifier.saveToHistory(
        scribblePath: item.scribblePath,
        generatedPath: item.generatedPath!,
        prompt: item.prompt,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      );

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
}
