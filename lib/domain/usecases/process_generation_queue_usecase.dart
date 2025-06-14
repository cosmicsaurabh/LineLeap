import 'dart:async';

import 'package:lineleap/domain/services/horde_generation_service.dart';

import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class ProcessGenerationQueueUseCase {
  final GenerationQueueRepository generationQueueRepository;
  final HordeGenerationService hordeGenerationService;
  Timer? _processingTimer;
  bool _isProcessing = false;

  ProcessGenerationQueueUseCase({
    required this.generationQueueRepository,
    required this.hordeGenerationService,
  });

  /// Start processing the generation queue at regular intervals
  void startProcessingQueue({Duration interval = const Duration(seconds: 5)}) {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(interval, (_) => processQueue());
  }

  /// Stop the queue processing
  void stopProcessingQueue() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// Process the next item in the queue if available and not already processing
  Future<void> processQueue() async {
    if (_isProcessing) {
      return; // Don't process if already processing a request
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
        return; // No requests to process
      }

      // Update status to submitting
      var updatingRequest = nextRequest.copyWith(
        status: GenerationStatus.submitting,
      );
      await generationQueueRepository.updateRequest(updatingRequest);

      try {
        // Process the generation request thjis should return a path to the generated file
        final result = await hordeGenerationService.generateFromPrompt(
          prompt: nextRequest.prompt,
          scribblePath: nextRequest.scribblePath,
        );

        // Update with success result
        updatingRequest = updatingRequest.copyWith(
          status: GenerationStatus.completed,
          generatedPath: result,
          completedAt: DateTime.now(),
        );

        //
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
    }
  }

  /// Process a specific request by ID immediately
  Future<void> processRequestById(String localId) async {
    if (_isProcessing) {
      return; // Don't interrupt current processing
    }

    try {
      _isProcessing = true;

      // Get the specific request
      final request = await generationQueueRepository.getRequestById(localId);
      if (request == null || request.status != GenerationStatus.queued) {
        return; // Request not found or not in queued state
      }

      // Update status to processing
      var updatingRequest = request.copyWith(
        status: GenerationStatus.submitting,
      );
      await generationQueueRepository.updateRequest(updatingRequest);

      try {
        // Process the generation request
        final result = await hordeGenerationService.generateFromPrompt(
          prompt: request.prompt,
          scribblePath: request.scribblePath,
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
    }
  }

  // Clean up resources
  void dispose() {
    stopProcessingQueue();
  }
}
