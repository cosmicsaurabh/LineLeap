import '../entities/scribble_transformation.dart';
import '../repositories/history_repository.dart';

class GetScribbleTransformationsFromHistory {
  final HistoryRepository repository;

  GetScribbleTransformationsFromHistory(this.repository);

  Future<List<ScribbleTransformation>> call() =>
      repository.getScribbleTransformationsFromHistory();
}
