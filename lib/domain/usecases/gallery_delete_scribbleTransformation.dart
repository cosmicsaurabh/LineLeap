import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';

class GalleryDeleteScribbleTransformation {
  final HistoryRepository repository;

  GalleryDeleteScribbleTransformation(this.repository);

  Future<void> call(ScribbleTransformation image) async {
    await repository.deleteHistoryImage(image);
  }
}
