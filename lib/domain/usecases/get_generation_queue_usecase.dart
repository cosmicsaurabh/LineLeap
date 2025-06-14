import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class GetGenerationQueueUseCase {
  final GenerationQueueRepository generationQueueRepository;

  GetGenerationQueueUseCase({required this.generationQueueRepository});

  /// Returns the current state of the generation queue
  Future<List<GenerationRequest>> call() async {
    return generationQueueRepository.getQueuedRequests();
  }

  /// Stream version if you want real-time updates
  Stream<List<GenerationRequest>> observe() {
    return generationQueueRepository.observeQueuedRequests();
  }

  //remove item from queue
  Future<void> removeFromQueue(GenerationRequest request) async {
    await generationQueueRepository.removeRequest(request.localId);
  }
}
