import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QueueEmptyState extends StatelessWidget {
  final VoidCallback onStartNewGeneration;

  const QueueEmptyState({Key? key, required this.onStartNewGeneration})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Add images to process!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onStartNewGeneration();
            },
            child: const Text('Start New Generation'),
          ),
        ],
      ),
    );
  }
}
