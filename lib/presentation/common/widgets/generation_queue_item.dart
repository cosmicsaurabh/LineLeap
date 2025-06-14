import 'dart:io';

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
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scribble and Generated thumbnails
          Column(
            children: [
              _buildThumbnailImage(
                context,
                path: request.scribblePath,
                iconData: Icons.edit_outlined,
              ),
              const SizedBox(height: 8),
              _buildThumbnailImage(
                context,
                path: request.generatedPath,
                status: request.status,
                isGeneratedImage: true,
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Content and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.prompt ?? 'No prompt provided',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.85),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildStatusWidget(context),
                if (request.status == GenerationStatus.polling)
                  const SizedBox(height: 8),
                if (request.status == GenerationStatus.polling)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildThumbnailImage(
    BuildContext context, {
    String? path,
    IconData? iconData,
    GenerationStatus? status,
    bool isGeneratedImage = false,
  }) {
    final theme = Theme.of(context);
    Widget child;

    if (path != null) {
      child = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.grey.shade400,
                size: 32,
              ),
            ),
      );
    } else if (isGeneratedImage) {
      switch (status) {
        case GenerationStatus.queued:
          child = Center(
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: Colors.orangeAccent[400],
              size: 32,
            ),
          );
          break;
        case GenerationStatus.submitting:
          child = Center(
            child: Icon(
              Icons.cloud_upload_outlined,
              color: Colors.blueAccent[400],
              size: 32,
            ),
          );
          break;
        case GenerationStatus.polling:
          child = Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          );
          break;
        case GenerationStatus
            .completed: // Should be covered by path != null, but as a fallback
          child = Center(
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green[600],
              size: 32,
            ),
          );
          break;
        default:
          child = Center(
            child: Icon(
              Icons.image_outlined,
              color: Colors.grey.shade400,
              size: 32,
            ),
          );
      }
    } else {
      child = Center(
        child: Icon(
          iconData ?? Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          11,
        ), // slightly less than container for inset effect
        child: child,
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    String label;
    Color color;
    Widget? leadingWidget;

    switch (request.status) {
      case GenerationStatus.queued:
        icon = Icons.pending_outlined;
        label = 'Pending';
        color = Colors.orangeAccent[700]!;
        leadingWidget = Icon(icon, size: 18, color: color);
        break;
      case GenerationStatus.submitting:
        label = 'Submitting...';
        color = Colors.blueAccent[700]!;
        leadingWidget = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
        break;
      case GenerationStatus.polling:
        label = 'Generating...';
        color = Colors.blueAccent[700]!;
        leadingWidget = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
        break;
      case GenerationStatus.completed:
        icon = Icons.check_circle_outline_rounded;
        label = 'Completed';
        color = Colors.green[700]!;
        leadingWidget = Icon(icon, size: 18, color: color);
        break;
      case GenerationStatus.failed:
        icon = Icons.error_outline_rounded;
        label = request.error ?? 'Failed';
        color = Colors.redAccent[700]!;
        leadingWidget = Icon(icon, size: 18, color: color);
        break;
    }

    return Row(
      children: [
        if (leadingWidget != null) leadingWidget,
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Assuming ActionButton is styled appropriately elsewhere.
    // Adding spacing for multiple buttons.
    switch (request.status) {
      case GenerationStatus.queued:
      case GenerationStatus
          .submitting: // Added submitting here for consistency if cancel is desired
      case GenerationStatus.polling:
        return ActionButton(
          onPressed: onRemove,
          icon: Icons.close_rounded,
          style: ActionButtonStyle.secondary,
          tooltip: 'Cancel',
        );

      case GenerationStatus.completed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton(
              onPressed: onView,
              icon: Icons.visibility_outlined,
              style: ActionButtonStyle.primary,
              tooltip: 'View',
            ),
            const SizedBox(height: 4),
            ActionButton(
              onPressed: onDownload,
              icon: Icons.download_outlined,
              style: ActionButtonStyle.primary,
              tooltip: 'Download & Save',
            ),
            const SizedBox(height: 4),
            ActionButton(
              onPressed: onRemove,
              icon: Icons.delete_outline_rounded,
              style: ActionButtonStyle.secondary,
              tooltip: 'Remove',
            ),
          ],
        );

      case GenerationStatus.failed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionButton(
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              style: ActionButtonStyle.primary,
              tooltip: 'Retry',
            ),
            const SizedBox(height: 4),
            ActionButton(
              onPressed: onRemove,
              icon: Icons.delete_outline_rounded,
              style: ActionButtonStyle.secondary,
              tooltip: 'Remove',
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
