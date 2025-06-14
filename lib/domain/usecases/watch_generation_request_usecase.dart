import 'dart:async';
import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class WatchGenerationRequestUseCase {
  final GenerationQueueRepository generationQueueRepository;

  WatchGenerationRequestUseCase({required this.generationQueueRepository});

  Stream<GenerationRequest?> call(String requestId) async* {
    const maxAttempts = 60;
    int attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      // Wait before checking status
      await Future.delayed(const Duration(seconds: 2));

      final request = await generationQueueRepository.getRequestById(requestId);

      yield request;

      // Stop watching if request is complete, failed, or doesn't exist
      if (request?.status == GenerationStatus.completed ||
          request?.status == GenerationStatus.failed ||
          request == null) {
        break;
      }
    }
  }
}
