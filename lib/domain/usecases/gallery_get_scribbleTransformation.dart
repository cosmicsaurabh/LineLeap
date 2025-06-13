import '../entities/scribble_transformation.dart';
import '../repositories/history_repository.dart';

class GalleryGetScribbleTransformation {
  final HistoryRepository repository;

  GalleryGetScribbleTransformation(this.repository);

  Future<List<ScribbleTransformation>> call() => repository.getHistoryImages();
}
