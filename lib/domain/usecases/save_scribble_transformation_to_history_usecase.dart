import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';

class SaveScribbleTransformationToHistoryUseCase {
  final HistoryRepository historyRepository;

  SaveScribbleTransformationToHistoryUseCase({required this.historyRepository});

  Future<void> call(ScribbleTransformation scribbleTransformation) async {
    await historyRepository.saveScribbleTransformationToHistory(
      scribbleTransformation,
    );
  }
}
