import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/widgets/generation_queue_item.dart';
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
                      onDownload: () => _downloadResult(context, request),
                      onView: () => _viewResult(context, request),
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
    // Implement retry logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Retrying generation...')));
  }

  void _downloadResult(BuildContext context, GenerationRequest request) {
    // Implement download logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Downloading...')));
  }

  void _viewResult(BuildContext context, GenerationRequest request) {
    // Implement view logic
    Navigator.pushNamed(context, '/view_result', arguments: request);
  }
}
