import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';

class SaveScribbletransformationToHistory {
  final HistoryRepository historyRepository;

  SaveScribbletransformationToHistory(this.historyRepository);

  Future<void> call(ScribbleTransformation image) async {
    await historyRepository.saveToHistory(image);
  }
}
