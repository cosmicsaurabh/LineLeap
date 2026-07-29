import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/domain/entities/generation_cancellation_token.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:lineleap/domain/services/horde_generation_service.dart';
import 'package:lineleap/domain/usecases/get_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';

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

  test('processQueue marks request failed when generation throws', () async {
    final request = GenerationRequest(
      localId: 'request-1',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.queued,
    );
    final repository = _FakeGenerationQueueRepository([request]);
    final service = _FakeHordeGenerationService(
      '/tmp/generated.png',
      error: Exception('provider unavailable'),
    );
    final useCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: service,
    );

    await useCase.processQueue();

    final updated = await repository.getRequestById('request-1');

    expect(updated?.status, GenerationStatus.failed);
    expect(updated?.error, contains('provider unavailable'));
    expect(repository.statusUpdates, contains(GenerationStatus.submitting));
    expect(repository.statusUpdates, contains(GenerationStatus.failed));
  });

  test('retryRequestById requeues failed and cancelled requests', () async {
    final failedRequest = GenerationRequest(
      localId: 'failed-request',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.failed,
      error: 'provider unavailable',
    );
    final cancelledRequest = GenerationRequest(
      localId: 'cancelled-request',
      prompt: 'a red bridge',
      scribblePath: '/tmp/scribble-2.png',
      status: GenerationStatus.cancelled,
      error: 'Generation cancelled',
    );
    final repository = _FakeGenerationQueueRepository([
      failedRequest,
      cancelledRequest,
    ]);
    final useCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: _FakeHordeGenerationService('/tmp/generated.png'),
    );

    await useCase.retryRequestById('failed-request');
    await useCase.retryRequestById('cancelled-request');

    final retriedFailed = await repository.getRequestById('failed-request');
    final retriedCancelled = await repository.getRequestById(
      'cancelled-request',
    );

    expect(retriedFailed?.status, GenerationStatus.queued);
    expect(retriedFailed?.error, isNull);
    expect(retriedCancelled?.status, GenerationStatus.queued);
    expect(retriedCancelled?.error, isNull);
  });

  test('retryRequestById surfaces repository write failures', () async {
    final request = GenerationRequest(
      localId: 'failed-request',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.failed,
      error: 'provider unavailable',
    );
    final repository = _FakeGenerationQueueRepository([request])
      ..updateError = Exception('queue write failed');
    final useCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: _FakeHordeGenerationService('/tmp/generated.png'),
    );

    await expectLater(
      useCase.retryRequestById('failed-request'),
      throwsA(isA<Exception>()),
    );
  });

  test('queue provider returns actionable feedback when retry fails', () async {
    final request = GenerationRequest(
      localId: 'failed-request',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.failed,
      error: 'provider unavailable',
    );
    final repository = _FakeGenerationQueueRepository([request])
      ..updateError = Exception('queue write failed');
    final processUseCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: _FakeHordeGenerationService('/tmp/generated.png'),
    );
    final provider = QueueStatusProvider(
      getQueueUseCase: GetGenerationQueueUseCase(
        generationQueueRepository: repository,
      ),
      processQueueUseCase: processUseCase,
    );
    addTearDown(provider.dispose);

    final message = await provider.retryGeneration(request);

    expect(message, contains('Couldn’t retry this generation'));
    expect(message, contains('try again'));
  });

  test('cancelRequestById cancels the active generation token', () async {
    final request = GenerationRequest(
      localId: 'request-1',
      prompt: 'a glass tower',
      scribblePath: '/tmp/scribble.png',
      status: GenerationStatus.queued,
    );
    final repository = _FakeGenerationQueueRepository([request]);
    final service = _FakeHordeGenerationService(
      '/tmp/generated.png',
      waitForCancellation: true,
    );
    final useCase = ProcessGenerationQueueUseCase(
      generationQueueRepository: repository,
      hordeGenerationService: service,
    );

    final processing = useCase.processQueue();
    await service.started.future;
    await useCase.cancelRequestById('request-1');
    await processing;

    final updated = await repository.getRequestById('request-1');

    expect(service.cancellationToken?.isCancelled, isTrue);
    expect(updated?.status, GenerationStatus.cancelled);
    expect(updated?.error, contains('cancelled'));
    expect(repository.statusUpdates, contains(GenerationStatus.cancelled));
  });
}

class _FakeHordeGenerationService implements HordeGenerationService {
  final String outputPath;
  final Object? error;
  final bool waitForCancellation;
  final List<String> prompts = [];
  final Completer<void> started = Completer<void>();
  GenerationCancellationToken? cancellationToken;

  _FakeHordeGenerationService(
    this.outputPath, {
    this.error,
    this.waitForCancellation = false,
  });

  @override
  Future<String> generateFromPrompt({
    required String prompt,
    required String scribblePath,
    void Function(int)? onProgress,
    GenerationCancellationToken? cancellationToken,
  }) async {
    prompts.add(prompt);
    this.cancellationToken = cancellationToken;
    if (!started.isCompleted) {
      started.complete();
    }
    onProgress?.call(50);
    if (error != null) {
      throw error!;
    }
    while (waitForCancellation && cancellationToken?.isCancelled != true) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    cancellationToken?.throwIfCancelled();
    return outputPath;
  }
}

class _FakeGenerationQueueRepository implements GenerationQueueRepository {
  final List<GenerationRequest> _requests;
  final List<GenerationStatus> statusUpdates = [];
  final StreamController<List<GenerationRequest>> _controller =
      StreamController<List<GenerationRequest>>.broadcast();
  Object? updateError;

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
    if (updateError case final error?) {
      throw error;
    }
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
