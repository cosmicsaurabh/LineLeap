import 'dart:async';

import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/datasources/local/generation_queue_local_datasource.dart';
import '../../domain/entities/generation_request.dart';
import '../../domain/repositories/generation_queue_repository.dart';

class GenerationQueueRepositoryImpl implements GenerationQueueRepository {
  final GenerationQueueNotifier _queueNotifier;
  final GenerationQueueLocalDatasource _localDatasource;

  GenerationQueueRepositoryImpl(
    this._queueNotifier,
    this._localDatasource,
  );

  /// Load persisted queue into memory and recover stuck requests
  Future<void> restoreQueue() async {
    final persisted = await _localDatasource.loadAll();
    for (final request in persisted) {
      // Reset stuck submitting/polling requests back to queued
      if (request.status == GenerationStatus.submitting ||
          request.status == GenerationStatus.polling) {
        final recovered = request.copyWith(status: GenerationStatus.queued);
        await _localDatasource.saveRequest(recovered);
        await _queueNotifier.addRequest(recovered);
      } else {
        await _queueNotifier.addRequest(request);
      }
    }
  }

  @override
  Future<void> enqueueRequest(GenerationRequest request) async {
    await _queueNotifier.addRequest(request);
    await _localDatasource.saveRequest(request);
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
    await _localDatasource.saveRequest(request);
  }

  @override
  Future<void> removeRequest(String localId) async {
    await _queueNotifier.removeRequest(localId);
    await _localDatasource.removeRequest(localId);
  }

  @override
  Stream<List<GenerationRequest>> observeQueuedRequests() {
    final controller = StreamController<List<GenerationRequest>>.broadcast();

    controller.add(_queueNotifier.queue);

    void listener() {
      controller.add(_queueNotifier.queue);
    }

    _queueNotifier.addListener(listener);

    controller.onCancel = () {
      _queueNotifier.removeListener(listener);
      controller.close();
    };

    return controller.stream;
  }
}
