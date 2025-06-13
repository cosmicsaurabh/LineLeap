import '../entities/generation_request.dart';
import '../repositories/generation_queue_repository.dart';

class GetGenerationQueueUseCase {
  final GenerationQueueRepository repository;

  GetGenerationQueueUseCase(this.repository);

  /// Returns the current state of the generation queue
  Future<List<GenerationRequest>> call() async {
    return repository.getQueuedRequests();
  }

  /// Stream version if you want real-time updates
  Stream<List<GenerationRequest>> observe() {
    return repository.observeQueuedRequests();
  }

  //remove item from queue
  Future<void> removeFromQueue(GenerationRequest request) async {
    await repository.removeRequest(request.localId);
  }
}
