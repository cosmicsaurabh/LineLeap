import '../entities/scribble_transformation.dart';
import '../repositories/gallery_repository.dart';

class GalleryGetScribbleTransformation {
  final GalleryRepository repository;

  GalleryGetScribbleTransformation(this.repository);

  Future<List<ScribbleTransformation>> call() => repository.getGalleryImages();
}
