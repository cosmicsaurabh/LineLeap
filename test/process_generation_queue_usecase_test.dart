import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:lineleap/domain/services/horde_generation_service.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';

void main() {
  test('processQueue completes the next queued generation request', () async {
    final request = GenerationRequest(
      localId: 'request-1',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.queued,
    );
    final repository = _FakeGenerationQueueRepository([request]);
    final service = _FakeHordeGenerationService('/tmp/generated.png');
    final useCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: service,
    );

    await useCase.processQueue();

    final updated = await repository.getRequestById('request-1');

    expect(updated?.status, GenerationStatus.completed);
    expect(updated?.generatedPath, '/tmp/generated.png');
    expect(updated?.completedAt, isNotNull);
    expect(service.prompts, ['a glass tower']);
    expect(repository.statusUpdates, contains(GenerationStatus.submitting));
    expect(repository.statusUpdates, contains(GenerationStatus.polling));
    expect(repository.statusUpdates, contains(GenerationStatus.completed));
  });
}

class _FakeHordeGenerationService implements HordeGenerationService {
  final String outputPath;
  final List<String> prompts = [];

  _FakeHordeGenerationService(this.outputPath);

  @override
  Future<String> generateFromPrompt({
    required String prompt,
    required String scribblePath,
    void Function(int)? onProgress,
  }) async {
    prompts.add(prompt);
    onProgress?.call(50);
    return outputPath;
  }
}

class _FakeGenerationQueueRepository implements GenerationQueueRepository {
  final List<GenerationRequest> _requests;
  final List<GenerationStatus> statusUpdates = [];
  final StreamController<List<GenerationRequest>> _controller =
      StreamController<List<GenerationRequest>>.broadcast();

  _FakeGenerationQueueRepository(this._requests);

  @override
  Future<void> enqueueRequest(GenerationRequest request) async {
    _requests.add(request);
    _controller.add(List.unmodifiable(_requests));
  }

  @override
  Future<List<GenerationRequest>> getQueuedRequests() async {
    return List.unmodifiable(_requests);
  }

  @override
  Future<GenerationRequest?> getRequestById(String localId) async {
    for (final request in _requests) {
      if (request.localId == localId) {
        return request;
      }
    }
    return null;
  }

  @override
  Stream<List<GenerationRequest>> observeQueuedRequests() {
    return _controller.stream;
  }

  @override
  Future<void> removeRequest(String localId) async {
    _requests.removeWhere((request) => request.localId == localId);
    _controller.add(List.unmodifiable(_requests));
  }

  @override
  Future<void> updateRequest(GenerationRequest request) async {
    final index = _requests.indexWhere(
      (existing) => existing.localId == request.localId,
    );
    if (index == -1) {
      _requests.add(request);
    } else {
      _requests[index] = request;
    }
    statusUpdates.add(request.status);
    _controller.add(List.unmodifiable(_requests));
  }
}
