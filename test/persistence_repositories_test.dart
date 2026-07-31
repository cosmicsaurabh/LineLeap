import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lineleap/core/service/image_device_interaction_service.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/datasources/local/generation_queue_local_datasource.dart';
import 'package:lineleap/data/models/scribble_transformation_hive_model.dart';
import 'package:lineleap/data/repositories/generation_queue_repo_impl.dart';
import 'package:lineleap/data/repositories/history_repository_impl.dart';
import 'package:lineleap/domain/entities/generation_request.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'lineleap_hive_test_',
    );
    addTearDown(() async {
      await Hive.close();
      if (await hiveDirectory.exists()) {
        await hiveDirectory.delete(recursive: true);
      }
    });
    Hive.init(hiveDirectory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScribbleTransformationHiveAdapter());
    }
  });

  group('GenerationQueueLocalDatasource', () {
    test(
      'round-trips populated and nullable fields after Hive is reopened',
      () async {
        final createdAt = DateTime.utc(2026, 7, 30, 6, 15);
        final completedAt = DateTime.utc(2026, 7, 30, 6, 20);
        final populated = GenerationRequest(
          localId: 'local-1',
          prompt: 'a glass city',
          scribblePath: 'queue/local-1-scribble.png',
          generationId: 'horde-42',
          generatedPath: 'queue/local-1-generated.png',
          status: GenerationStatus.failed,
          error: 'provider unavailable',
          createdAt: createdAt,
          completedAt: completedAt,
        );
        final nullable = GenerationRequest(
          localId: 'local-2',
          prompt: 'a paper forest',
          scribblePath: 'queue/local-2-scribble.png',
        );

        final datasource = GenerationQueueLocalDatasource();
        await datasource.saveRequest(populated);
        await datasource.saveRequest(nullable);
        await _reopenHive(hiveDirectory);

        final restored = await GenerationQueueLocalDatasource().loadAll();
        final restoredById = {
          for (final request in restored) request.localId: request,
        };

        expect(restored, hasLength(2));
        _expectSameRequest(restoredById['local-1']!, populated);
        _expectSameRequest(restoredById['local-2']!, nullable);
      },
    );

    test('keeps the persisted GenerationStatus index order stable', () {
      expect(GenerationStatus.values.map((status) => status.name), [
        'queued',
        'submitting',
        'polling',
        'completed',
        'failed',
        'cancelled',
      ]);
    });
  });

  group('GenerationQueueRepositoryImpl', () {
    test(
      'keeps memory and Hive aligned across enqueue, update, and remove',
      () async {
        final notifier = GenerationQueueNotifier();
        addTearDown(notifier.dispose);
        final datasource = GenerationQueueLocalDatasource();
        final repository = GenerationQueueRepositoryImpl(notifier, datasource);
        final original = GenerationRequest(
          localId: 'local-1',
          prompt: 'a glass city',
          scribblePath: 'queue/local-1-scribble.png',
          status: GenerationStatus.queued,
          createdAt: DateTime.utc(2026, 7, 30, 6, 15),
        );

        await repository.enqueueRequest(original);

        expect(await repository.getQueuedRequests(), hasLength(1));
        _expectSameRequest(
          (await repository.getRequestById(original.localId))!,
          original,
        );
        _expectSameRequest((await datasource.loadAll()).single, original);

        final polling = original.copyWith(
          generationId: 'horde-42',
          status: GenerationStatus.polling,
        );
        await repository.updateRequest(polling);

        _expectSameRequest(
          (await repository.getQueuedRequests()).single,
          polling,
        );
        _expectSameRequest(
          (await repository.getRequestById(original.localId))!,
          polling,
        );
        _expectSameRequest((await datasource.loadAll()).single, polling);

        await repository.removeRequest(original.localId);

        expect(await repository.getQueuedRequests(), isEmpty);
        expect(await repository.getRequestById(original.localId), isNull);
        expect(await datasource.loadAll(), isEmpty);
      },
    );

    test('re-enqueueing a local ID replaces it in both stores', () async {
      final notifier = GenerationQueueNotifier();
      addTearDown(notifier.dispose);
      final datasource = GenerationQueueLocalDatasource();
      final repository = GenerationQueueRepositoryImpl(notifier, datasource);
      final original = GenerationRequest(
        localId: 'local-1',
        prompt: 'first prompt',
        scribblePath: 'queue/local-1-scribble.png',
      );
      final replacement = GenerationRequest(
        localId: 'local-1',
        prompt: 'replacement prompt',
        scribblePath: 'queue/local-1-scribble.png',
        status: GenerationStatus.failed,
        error: 'provider unavailable',
      );

      await repository.enqueueRequest(original);
      await repository.enqueueRequest(replacement);

      final inMemory = await repository.getQueuedRequests();
      final persisted = await datasource.loadAll();
      expect(inMemory, hasLength(1));
      expect(persisted, hasLength(1));
      _expectSameRequest(inMemory.single, replacement);
      _expectSameRequest(persisted.single, replacement);
    });

    test('observes the initial queue and each repository mutation', () async {
      final notifier = GenerationQueueNotifier();
      addTearDown(notifier.dispose);
      final repository = GenerationQueueRepositoryImpl(
        notifier,
        GenerationQueueLocalDatasource(),
      );
      final request = GenerationRequest(
        localId: 'local-1',
        prompt: 'a glass city',
        scribblePath: 'queue/local-1-scribble.png',
      );
      final iterator = StreamIterator(repository.observeQueuedRequests());
      addTearDown(iterator.cancel);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      await repository.enqueueRequest(request);
      expect(await iterator.moveNext(), isTrue);
      _expectSameRequest(iterator.current.single, request);

      final failed = request.copyWith(
        status: GenerationStatus.failed,
        error: 'provider unavailable',
      );
      await repository.updateRequest(failed);
      expect(await iterator.moveNext(), isTrue);
      _expectSameRequest(iterator.current.single, failed);

      await repository.removeRequest(request.localId);
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);
    });

    test(
      'restores persisted requests and recovers interrupted states',
      () async {
        final datasource = GenerationQueueLocalDatasource();
        final submitting = GenerationRequest(
          localId: 'submitting',
          prompt: 'first',
          scribblePath: 'queue/first.png',
          status: GenerationStatus.submitting,
        );
        final polling = GenerationRequest(
          localId: 'polling',
          prompt: 'second',
          scribblePath: 'queue/second.png',
          generationId: 'horde-42',
          status: GenerationStatus.polling,
        );
        final completed = GenerationRequest(
          localId: 'completed',
          prompt: 'third',
          scribblePath: 'queue/third.png',
          generatedPath: 'queue/third-generated.png',
          status: GenerationStatus.completed,
          completedAt: DateTime.utc(2026, 7, 30, 6, 20),
        );
        await datasource.saveRequest(submitting);
        await datasource.saveRequest(polling);
        await datasource.saveRequest(completed);
        await _reopenHive(hiveDirectory);

        final reopenedDatasource = GenerationQueueLocalDatasource();
        final notifier = GenerationQueueNotifier();
        addTearDown(notifier.dispose);
        final repository = GenerationQueueRepositoryImpl(
          notifier,
          reopenedDatasource,
        );

        await repository.restoreQueue();

        final inMemory = {
          for (final request in await repository.getQueuedRequests())
            request.localId: request,
        };
        final persisted = {
          for (final request in await reopenedDatasource.loadAll())
            request.localId: request,
        };
        expect(inMemory.keys, unorderedEquals(persisted.keys));
        expect(inMemory['submitting']?.status, GenerationStatus.queued);
        expect(inMemory['polling']?.status, GenerationStatus.queued);
        expect(inMemory['polling']?.generationId, 'horde-42');
        expect(inMemory['completed']?.status, GenerationStatus.completed);
        expect(persisted['submitting']?.status, GenerationStatus.queued);
        expect(persisted['polling']?.status, GenerationStatus.queued);
        expect(persisted['completed']?.status, GenerationStatus.completed);
      },
    );
  });

  group('HistoryRepositoryImpl', () {
    test(
      'saves, reloads, and deletes a transformation with its files',
      () async {
        final fileService = _RecordingImageDeviceInteractionService();
        var box = await Hive.openBox<ScribbleTransformationHive>(
          'gallery_history',
        );
        var repository = HistoryRepositoryImpl(box, fileService);
        final original = ScribbleTransformation(
          generatedImagePath: 'gallery/generated.png',
          scribbleImagePath: 'gallery/scribble.png',
          prompt: 'a glass city ✨',
          timestamp: '2026-07-30T06:20:00.000Z',
        );
        final survivor = ScribbleTransformation(
          generatedImagePath: 'gallery/survivor-generated.png',
          scribbleImagePath: 'gallery/survivor-scribble.png',
          prompt: 'a paper forest',
          timestamp: '2026-07-30T06:21:00.000Z',
        );

        await repository.saveScribbleTransformationToHistory(original);
        await repository.saveScribbleTransformationToHistory(survivor);
        await _reopenHive(hiveDirectory);

        box = await Hive.openBox<ScribbleTransformationHive>('gallery_history');
        repository = HistoryRepositoryImpl(box, fileService);
        final restored =
            await repository.getScribbleTransformationsFromHistory();
        final restoredOriginal = restored.singleWhere(
          (item) => item.prompt == original.prompt,
        );

        expect(restored, hasLength(2));
        _expectSameTransformation(restoredOriginal, original);

        await repository.deleteScribbleTransformationFromHistory(
          restoredOriginal,
        );

        expect(box.values, hasLength(1));
        _expectSameTransformation(box.values.single.toEntity(), survivor);
        expect(fileService.deletedPaths, [
          'gallery/generated.png',
          'gallery/scribble.png',
        ]);

        await _reopenHive(hiveDirectory);
        box = await Hive.openBox<ScribbleTransformationHive>('gallery_history');
        repository = HistoryRepositoryImpl(box, fileService);
        final afterRestart =
            await repository.getScribbleTransformationsFromHistory();
        expect(afterRestart, hasLength(1));
        _expectSameTransformation(afterRestart.single, survivor);
      },
    );

    test('rejects a missing transformation without deleting files', () async {
      final fileService = _RecordingImageDeviceInteractionService();
      final box = await Hive.openBox<ScribbleTransformationHive>(
        'gallery_history',
      );
      final repository = HistoryRepositoryImpl(box, fileService);
      final existing = ScribbleTransformation(
        generatedImagePath: 'gallery/existing-generated.png',
        scribbleImagePath: 'gallery/existing-scribble.png',
        prompt: 'existing',
        timestamp: '2026-07-30T06:20:00.000Z',
      );
      final missing = ScribbleTransformation(
        generatedImagePath: 'gallery/missing-generated.png',
        scribbleImagePath: 'gallery/missing-scribble.png',
        prompt: 'missing',
        timestamp: '2026-07-30T06:21:00.000Z',
      );
      await repository.saveScribbleTransformationToHistory(existing);

      await expectLater(
        repository.deleteScribbleTransformationFromHistory(missing),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Image not found'),
          ),
        ),
      );

      expect(box.values, hasLength(1));
      _expectSameTransformation(box.values.single.toEntity(), existing);
      expect(fileService.deletedPaths, isEmpty);
    });
  });
}

Future<void> _reopenHive(Directory hiveDirectory) async {
  await Hive.close();
  Hive.init(hiveDirectory.path);
}

void _expectSameRequest(GenerationRequest actual, GenerationRequest expected) {
  expect(actual.localId, expected.localId);
  expect(actual.prompt, expected.prompt);
  expect(actual.scribblePath, expected.scribblePath);
  expect(actual.generationId, expected.generationId);
  expect(actual.generatedPath, expected.generatedPath);
  expect(actual.status, expected.status);
  expect(actual.error, expected.error);
  expect(actual.createdAt, expected.createdAt);
  expect(actual.completedAt, expected.completedAt);
}

void _expectSameTransformation(
  ScribbleTransformation actual,
  ScribbleTransformation expected,
) {
  expect(actual.generatedImagePath, expected.generatedImagePath);
  expect(actual.scribbleImagePath, expected.scribbleImagePath);
  expect(actual.prompt, expected.prompt);
  expect(actual.timestamp, expected.timestamp);
}

class _RecordingImageDeviceInteractionService
    extends ImageDeviceInteractionService {
  final List<String> deletedPaths = [];

  @override
  Future<void> deleteImageFromDevice(String imagePath) async {
    deletedPaths.add(imagePath);
  }
}
