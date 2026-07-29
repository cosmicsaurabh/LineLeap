import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:lineleap/domain/repositories/image_save_load_delete_repository.dart';
import 'package:lineleap/domain/usecases/enqueue_generation_request_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_bytes_return_path_usecase.dart';
import 'package:lineleap/domain/usecases/watch_generation_request_usecase.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/widgets/view.dart';
import 'package:lineleap/presentation/features/scribble/prompt_input_dialog.dart';

void main() {
  group('generation feedback', () {
    testWidgets(
      'a canvas capture failure exposes an actionable error and stops capturing',
      (tester) async {
        final queueRepository = _FakeGenerationQueueRepository();
        final imageRepository = _FakeImageRepository();
        final provider = GenerationProvider(
          enqueueUseCase: EnqueueGenerationRequestUseCase(
            generationQueueRepository: queueRepository,
          ),
          queueRepository: queueRepository,
          saveImageUseCase: SaveImagebytesReturnPathUseCase(
            imageSaveLoadDeleteRepository: imageRepository,
          ),
          watchRequestUseCase: WatchGenerationRequestUseCase(
            generationQueueRepository: queueRepository,
          ),
        );
        final capturingStates = <bool>[];
        provider.addListener(() => capturingStates.add(provider.isCapturing));
        addTearDown(provider.dispose);

        final request = await provider.sequenceForGenerationRequest(
          prompt: 'a bright lighthouse',
          canvasKey: GlobalKey(),
        );

        expect(request, isNull);
        expect(provider.isCapturing, isFalse);
        expect(provider.error, contains('Couldn’t capture the drawing'));
        expect(provider.error, contains('try again'));
        expect(capturingStates, containsAllInOrder([true, false]));
        expect(imageRepository.saveCalls, 0);
        expect(queueRepository.enqueueCalls, 0);
      },
    );

    testWidgets(
      'the prompt explains the internet and shared anonymous queue constraints',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: PromptInputDialog(initialPrompt: '')),
        );

        expect(find.textContaining('internet connection'), findsOneWidget);
        expect(find.textContaining('shared anonymous queue'), findsOneWidget);
        expect(
          find.textContaining('actual connection or provider result'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a failed request shows its stored terminal reason and one Retry action',
      (tester) async {
        var retryCalls = 0;
        final request = GenerationRequest(
          localId: 'failed-request',
          prompt: 'a bright lighthouse',
          scribblePath: '/tmp/scribble.png',
          status: GenerationStatus.failed,
          error: 'AI Horde timed out while processing this request.',
        );

        await tester.pumpWidget(
          _StatusSectionHarness(request: request, onRetry: (_) => retryCalls++),
        );

        expect(
          find.text('AI Horde timed out while processing this request.'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);

        await tester.tap(find.text('Retry'));
        await tester.pump();

        expect(retryCalls, 1);
      },
    );

    testWidgets('a completed request does not offer Retry', (tester) async {
      final request = GenerationRequest(
        localId: 'completed-request',
        prompt: 'a bright lighthouse',
        scribblePath: '/tmp/scribble.png',
        generatedPath: '/tmp/generated.png',
        status: GenerationStatus.completed,
      );

      await tester.pumpWidget(
        _StatusSectionHarness(
          request: request,
          onRetry: (_) => fail('completed requests cannot be retried'),
        ),
      );

      expect(find.text('Retry'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });
  });
}

class _StatusSectionHarness extends StatelessWidget {
  final GenerationRequest request;
  final ValueChanged<GenerationRequest> onRetry;

  const _StatusSectionHarness({required this.request, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder:
              (context) => buildStatusSection(
                context,
                request,
                onRetry,
                (_) {},
                (_) {},
                (_) {},
              ),
        ),
      ),
    );
  }
}

class _FakeImageRepository implements ImageSaveLoadDeleteRepository {
  int saveCalls = 0;

  @override
  Future<void> deleteImageFromPath(String storagePath) async {}

  @override
  Future<Uint8List> getImageBytesFromPath(String storagePath) async {
    return Uint8List(0);
  }

  @override
  Future<String> saveImageBytesReturnPath(Uint8List imageBytes) async {
    saveCalls++;
    return '/tmp/scribble.png';
  }
}

class _FakeGenerationQueueRepository implements GenerationQueueRepository {
  final List<GenerationRequest> _requests = [];
  final StreamController<List<GenerationRequest>> _controller =
      StreamController<List<GenerationRequest>>.broadcast();
  int enqueueCalls = 0;

  @override
  Future<void> enqueueRequest(GenerationRequest request) async {
    enqueueCalls++;
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
    _controller.add(List.unmodifiable(_requests));
  }
}
