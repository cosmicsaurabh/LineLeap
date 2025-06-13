import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';

class GalleryDeleteScribbleTransformation {
  final GalleryRepository repository;

  GalleryDeleteScribbleTransformation(this.repository);

  Future<void> call(ScribbleTransformation image) async {
    await repository.deleteGalleryImage(image);
  }
}
