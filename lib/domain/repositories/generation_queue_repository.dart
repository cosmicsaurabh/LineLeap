import '../entities/generation_request.dart';

abstract class GenerationQueueRepository {
  /// Adds a new request to the generation queue
  Future<void> enqueueRequest(GenerationRequest request);

  /// Gets all queued generation requests
  Future<List<GenerationRequest>> getQueuedRequests();

  /// Gets a specific request by its local ID
  Future<GenerationRequest?> getRequestById(String localId);

  /// Updates an existing request in the queue
  Future<void> updateRequest(GenerationRequest request);

  /// Removes a request from the queue
  Future<void> removeRequest(String localId);

  /// Returns a stream of queue updates
  Stream<List<GenerationRequest>> observeQueuedRequests();
}
