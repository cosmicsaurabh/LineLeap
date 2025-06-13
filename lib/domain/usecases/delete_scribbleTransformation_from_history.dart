import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';

class DeleteScribbleTransformationFromHistory {
  final HistoryRepository repository;

  DeleteScribbleTransformationFromHistory(this.repository);

  Future<void> call(ScribbleTransformation scribbleTransformation) async {
    await repository.deleteScribbleTransformationFromHistory(
      scribbleTransformation,
    );
  }
}
