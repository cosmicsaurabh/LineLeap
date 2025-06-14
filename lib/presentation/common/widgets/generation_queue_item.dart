import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';

class GenerationQueueItem extends StatelessWidget {
  final GenerationRequest request;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final VoidCallback onDownload;
  final VoidCallback onView;

  const GenerationQueueItem({
    Key? key,
    required this.request,
    required this.onRemove,
    required this.onRetry,
    required this.onDownload,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Scribble thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  request.scribblePath != null
                      ? Image.asset(request.scribblePath!, fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Content and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.prompt ?? 'No prompt',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusWidget(context),
                if (request.status == GenerationStatus.polling)
                  const SizedBox(height: 8),
                if (request.status == GenerationStatus.polling)
                  LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    switch (request.status) {
      case GenerationStatus.queued:
        return Row(
          children: [
            Icon(Icons.pending, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        );
      case GenerationStatus.polling:
        return Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 4),
            Text(
              'Generating...',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        );
      case GenerationStatus.completed:
        return Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Completed',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        );
      case GenerationStatus.failed:
        return Row(
          children: [
            Icon(Icons.error, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              request.error ?? 'Failed',
              style: TextStyle(color: Colors.red, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      case GenerationStatus.failed:
        return Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              'Timed out',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (request.status) {
      case GenerationStatus.queued:
      case GenerationStatus.polling:
        return IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: onRemove,
          tooltip: 'Cancel',
        );
      case GenerationStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: onView,
              tooltip: 'View',
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.green),
              onPressed: onDownload,
              tooltip: 'Download',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        );

      case GenerationStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              onPressed: onRetry,
              tooltip: 'Retry',
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
