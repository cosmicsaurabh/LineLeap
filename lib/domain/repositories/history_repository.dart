import '../entities/scribble_transformation.dart';

abstract class HistoryRepository {
  Future<List<ScribbleTransformation>> getScribbleTransformationsFromHistory();
  Future<void> deleteScribbleTransformationFromHistory(
    ScribbleTransformation scribbleTransformation,
  );
  Future<void> saveScribbleTransformationToHistory(
    ScribbleTransformation scribbleTransformation,
  );
}
