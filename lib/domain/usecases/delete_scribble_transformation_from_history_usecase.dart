import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';

class DeleteScribbleTransformationFromHistoryUseCase {
  final HistoryRepository historyRepository;

  DeleteScribbleTransformationFromHistoryUseCase({
    required this.historyRepository,
  });

  Future<void> call(ScribbleTransformation scribbleTransformation) async {
    await historyRepository.deleteScribbleTransformationFromHistory(
      scribbleTransformation,
    );
  }
}
