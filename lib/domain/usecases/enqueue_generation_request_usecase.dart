import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:uuid/uuid.dart';
import '../entities/generation_request.dart';

class EnqueueGenerationRequestUseCase {
  final GenerationQueueRepository generationQueueRepository;
  final Uuid _uuid = const Uuid();

  EnqueueGenerationRequestUseCase({required this.generationQueueRepository});

  Future<GenerationRequest> call({
    required String prompt,
    required String scribblePath,
  }) async {
    // Generate a local UUID for the request
    final localId = _uuid.v4();

    // Create a new generation request
    final request = GenerationRequest(
      localId: localId,
      prompt: prompt,
      scribblePath: scribblePath,
      status: GenerationStatus.queued,
    );

    // Add to repository (which handles both in-memory queue and persistence)
    await generationQueueRepository.enqueueRequest(request);

    return request;
  }
}
