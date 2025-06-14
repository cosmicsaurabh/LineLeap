// Example: adding a queue view to a screen
import 'package:flutter/material.dart';
import 'package:lineleap/presentation/common/widgets/generation_queue.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:provider/provider.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generation Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<QueueStatusProvider>().refreshQueue();
            },
          ),
        ],
      ),
      body: const GenerationQueueWidget(),
    );
  }
}
