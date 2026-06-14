import 'dart:async';
import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class WatchGenerationRequestUseCase {
  final GenerationQueueRepository generationQueueRepository;

  WatchGenerationRequestUseCase({required this.generationQueueRepository});

  Stream<GenerationRequest?> call(String requestId) async* {
    final initialRequest = await generationQueueRepository.getRequestById(
      requestId,
    );
    yield initialRequest;

    if (_isTerminal(initialRequest)) {
      return;
    }

    await for (final requests
        in generationQueueRepository.observeQueuedRequests()) {
      GenerationRequest? request;
      for (final item in requests) {
        if (item.localId == requestId) {
          request = item;
          break;
        }
      }

      yield request;

      if (_isTerminal(request)) {
        break;
      }
    }
  }

  bool _isTerminal(GenerationRequest? request) {
    return request == null ||
        request.status == GenerationStatus.completed ||
        request.status == GenerationStatus.failed ||
        request.status == GenerationStatus.cancelled;
  }
}
