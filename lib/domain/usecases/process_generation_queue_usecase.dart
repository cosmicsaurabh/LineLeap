import 'dart:async';

import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/domain/services/horde_generation_service.dart';

import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class ProcessGenerationQueueUseCase {
  final GenerationQueueRepository generationQueueRepository;
  final HordeGenerationService hordeGenerationService;
  final GenerationQueueNotifier _queueNotifier;
  bool _isProcessing = false;

  ProcessGenerationQueueUseCase({
    required this.generationQueueRepository,
    required this.hordeGenerationService,
    required GenerationQueueNotifier queueNotifier,
  }) : _queueNotifier = queueNotifier;

  /// Start listening for queue changes and process automatically
  void startListening() {
    _queueNotifier.addListener(_onQueueChanged);
    // Process any items already in the queue (e.g. recovered from persistence)
    _onQueueChanged();
  }

  void _onQueueChanged() {
    processQueue();
  }

  /// Process the next item in the queue if available and not already processing
  Future<void> processQueue() async {
    if (_isProcessing) {
      return;
    }

    try {
      _isProcessing = true;

      // Get all queued requests
      final requests = await generationQueueRepository.getQueuedRequests();

      // Find the first request with status 'queued'
      GenerationRequest? nextRequest;
      nextRequest = requests.cast<GenerationRequest?>().firstWhere(
        (req) => req?.status == GenerationStatus.queued,
        orElse: () => null,
      );

      if (nextRequest == null) {
        return;
      }

      // Update status to submitting
      var updatingRequest = nextRequest.copyWith(
        status: GenerationStatus.submitting,
      );
      await generationQueueRepository.updateRequest(updatingRequest);

      try {
        // Process the generation request
        final result = await hordeGenerationService.generateFromPrompt(
          prompt: nextRequest.prompt,
          scribblePath: nextRequest.scribblePath,
          onProgress: (progress) async {
            updatingRequest = updatingRequest.copyWith(
              status: GenerationStatus.polling,
            );
            await generationQueueRepository.updateRequest(updatingRequest);
          },
        );

        // Update with success result
        updatingRequest = updatingRequest.copyWith(
          status: GenerationStatus.completed,
          generatedPath: result,
          completedAt: DateTime.now(),
        );
      } catch (error) {
        // Update with error
        updatingRequest = updatingRequest.copyWith(
          status: GenerationStatus.failed,
          error: error.toString(),
        );
      }

      // Update the request in repository
      await generationQueueRepository.updateRequest(updatingRequest);
    } finally {
      _isProcessing = false;
      // After finishing, check if there are more queued items
      _checkForMore();
    }
  }

  /// After processing one item, check if there's another queued item to pick up
  void _checkForMore() {
    Future.microtask(() async {
      final requests = await generationQueueRepository.getQueuedRequests();
      final hasMore = requests.any((r) => r.status == GenerationStatus.queued);
      if (hasMore) {
        processQueue();
      }
    });
  }

  Future<void> retryRequestById(String localId) async {
    try {
      final request = await generationQueueRepository.getRequestById(localId);
      if (request == null || request.status != GenerationStatus.failed) {
        return;
      }

      var updatingRequest = request.copyWith(status: GenerationStatus.queued);
      await generationQueueRepository.updateRequest(updatingRequest);
    } catch (e) {
      // Handle error
    }
  }

  void dispose() {
    _queueNotifier.removeListener(_onQueueChanged);
  }
}
