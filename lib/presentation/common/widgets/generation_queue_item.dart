import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/common/widgets/action_button.dart';

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
          Column(
            children: [
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
                          ? Image.asset(
                            request.scribblePath!,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
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
                      request.generatedPath != null
                          ? Image.asset(
                            request.generatedPath!,
                            fit: BoxFit.cover,
                          )
                          : request.status == GenerationStatus.queued
                          ? const Icon(
                            Icons.hourglass_bottom,
                            color: Colors.yellow,
                          )
                          : request.status == GenerationStatus.submitting
                          ? const Icon(Icons.upload, color: Colors.grey)
                          : request.status == GenerationStatus.polling
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : request.status == GenerationStatus.completed
                          ? Image.asset(
                            request.generatedPath!,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ],
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
      case GenerationStatus.submitting:
        return Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 4),
            Text(
              'Submitting...',
              style: TextStyle(color: Colors.blue, fontSize: 12),
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
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (request.status) {
      case GenerationStatus.queued:
      case GenerationStatus.polling:
        return ActionButton(
          onPressed: onRemove,
          icon: Icons.close,
          // label: 'Cancel',
          style: ActionButtonStyle.secondary,
        );

      case GenerationStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton(
              onPressed: onView,
              icon: Icons.visibility,
              // label: 'View',
              style: ActionButtonStyle.primary,
            ),
            ActionButton(
              onPressed: onDownload,
              icon: Icons.download,
              // label: 'Download',
              style: ActionButtonStyle.primary,
            ),
            ActionButton(
              onPressed: onRemove,
              icon: Icons.close,
              // label: 'Remove',
              style: ActionButtonStyle.secondary,
            ),
          ],
        );

      case GenerationStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton(
              onPressed: onRetry,
              icon: Icons.refresh,
              // label: 'Retry',
              style: ActionButtonStyle.primary,
            ),
            ActionButton(
              onPressed: onRemove,
              icon: Icons.close,
              // label: 'Remove',
              style: ActionButtonStyle.secondary,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
