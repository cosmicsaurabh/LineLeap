import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';
import 'package:lineleap/domain/usecases/delete_scribbletransformation_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/get_scribble_transformations_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/save_scribble_transformation_to_history_usecase.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/features/gallery/gallery_page.dart';
import 'package:provider/provider.dart';

void main() {
  group('GalleryNotifier failure feedback', () {
    test(
      'load failure exposes an actionable error and stops loading',
      () async {
        final repository =
            _FakeHistoryRepository()..loadError = Exception('disk');
        final notifier = _buildNotifier(repository);

        await notifier.loadImages();

        expect(notifier.isLoading, isFalse);
        expect(notifier.scribbleTransformations, isEmpty);
        expect(notifier.loadError, contains("Couldn't load History"));
        expect(notifier.loadError, contains('try again'));
        expect(notifier.error, notifier.loadError);
      },
    );

    test(
      'save failure returns false and explains that the image is safe',
      () async {
        final repository =
            _FakeHistoryRepository()..saveError = Exception('write failed');
        final notifier = _buildNotifier(repository);

        final saved = await notifier.saveToHistory(
          scribblePath: '/tmp/sketch.png',
          generatedPath: '/tmp/generated.png',
          prompt: 'a glass tower',
          timestamp: '2026-07-29T10:00:00.000Z',
        );

        expect(saved, isFalse);
        expect(notifier.scribbleTransformations, isEmpty);
        expect(notifier.operationError, contains("Couldn't add this image"));
        expect(notifier.operationError, contains('still in the queue'));
        expect(notifier.operationError, contains('try again'));
        expect(notifier.error, notifier.operationError);
      },
    );

    test(
      'delete failure returns false and keeps the image in History',
      () async {
        final original = _transformation();
        final repository = _FakeHistoryRepository([original]);
        final notifier = _buildNotifier(repository);
        await notifier.loadImages();
        final selected = notifier.scribbleTransformations.single;
        repository.deleteError = Exception('delete failed');

        final deleted = await notifier.deleteImage(selected);

        expect(deleted, isFalse);
        expect(notifier.scribbleTransformations, hasLength(1));
        expect(notifier.scribbleTransformations.single, same(selected));
        expect(notifier.operationError, contains("Couldn't delete this image"));
        expect(notifier.operationError, contains('still in History'));
        expect(notifier.operationError, contains('try again'));
      },
    );
  });

  testWidgets('History load failure is visible and can be retried', (
    tester,
  ) async {
    final repository = _FakeHistoryRepository()..loadError = Exception('disk');
    final notifier = _buildNotifier(repository);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: const MaterialApp(home: GalleryPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('History unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.text('History unavailable'), findsOneWidget);
  });
}

GalleryNotifier _buildNotifier(HistoryRepository repository) {
  return GalleryNotifier(
    getGalleryImagesUseCase: GetScribbleTransformationsFromHistoryUseCase(
      historyRepository: repository,
    ),
    saveImageToGalleryUseCase: SaveScribbleTransformationToHistoryUseCase(
      historyRepository: repository,
    ),
    deleteGalleryImageUseCase: DeleteScribbleTransformationFromHistoryUseCase(
      historyRepository: repository,
    ),
  );
}

ScribbleTransformation _transformation() {
  return ScribbleTransformation(
    generatedImagePath: '/tmp/generated.png',
    scribbleImagePath: '/tmp/sketch.png',
    prompt: 'a glass tower',
    timestamp: '2026-07-29T10:00:00.000Z',
  );
}

class _FakeHistoryRepository implements HistoryRepository {
  final List<ScribbleTransformation> transformations;
  Object? loadError;
  Object? saveError;
  Object? deleteError;
  int loadCalls = 0;

  _FakeHistoryRepository([
    List<ScribbleTransformation> transformations = const [],
  ]) : transformations = List.of(transformations);

  @override
  Future<List<ScribbleTransformation>>
  getScribbleTransformationsFromHistory() async {
    loadCalls += 1;
    if (loadError case final error?) {
      throw error;
    }
    return List.unmodifiable(transformations);
  }

  @override
  Future<void> saveScribbleTransformationToHistory(
    ScribbleTransformation scribbleTransformation,
  ) async {
    if (saveError case final error?) {
      throw error;
    }
    transformations.add(scribbleTransformation);
  }

  @override
  Future<void> deleteScribbleTransformationFromHistory(
    ScribbleTransformation scribbleTransformation,
  ) async {
    if (deleteError case final error?) {
      throw error;
    }
    transformations.remove(scribbleTransformation);
  }
}
