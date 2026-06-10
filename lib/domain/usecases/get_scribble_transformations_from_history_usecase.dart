import '../entities/scribble_transformation.dart';
import '../repositories/history_repository.dart';

class GetScribbleTransformationsFromHistoryUseCase {
  final HistoryRepository historyRepository;

  GetScribbleTransformationsFromHistoryUseCase({
    required this.historyRepository,
  });

  Future<List<ScribbleTransformation>> call() =>
      historyRepository.getScribbleTransformationsFromHistory();
}
