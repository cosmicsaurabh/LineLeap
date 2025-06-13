import '../entities/scribble_transformation.dart';

abstract class HistoryRepository {
  Future<List<ScribbleTransformation>> getHistoryImages();
  Future<void> deleteHistoryImage(ScribbleTransformation image);
  Future<void> saveToHistory(ScribbleTransformation image);
}
