import 'dart:async';

import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import '../../domain/entities/generation_request.dart';
import '../../domain/repositories/generation_queue_repository.dart';

class GenerationQueueRepositoryImpl implements GenerationQueueRepository {
  // In-memory queue notifier
  final GenerationQueueNotifier _queueNotifier;

  GenerationQueueRepositoryImpl(
    this._queueNotifier,
    // [this._storageService]
  );

  @override
  Future<void> enqueueRequest(GenerationRequest request) async {
    // Add to in-memory queue
    await _queueNotifier.addRequest(request);
  }

  @override
  Future<List<GenerationRequest>> getQueuedRequests() async {
    return _queueNotifier.queue;
  }

  @override
  Future<GenerationRequest?> getRequestById(String localId) async {
    try {
      return _queueNotifier.queue.firstWhere(
        (request) => request.localId == localId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateRequest(GenerationRequest request) async {
    await _queueNotifier.updateRequest(request);
  }

  @override
  Future<void> removeRequest(String localId) async {
    await _queueNotifier.removeRequest(localId);
  }

  @override
  Stream<List<GenerationRequest>> observeQueuedRequests() {
    // Create a StreamController to emit queue updates
    final controller = StreamController<List<GenerationRequest>>.broadcast();

    // Add the current queue immediately
    controller.add(_queueNotifier.queue);

    // Add a listener to the notifier to emit updates when the queue changes
    void listener() {
      controller.add(_queueNotifier.queue);
    }

    _queueNotifier.addListener(listener);

    // Clean up when the stream is no longer needed
    controller.onCancel = () {
      _queueNotifier.removeListener(listener);
      controller.close();
    };

    return controller.stream;
  }
}
