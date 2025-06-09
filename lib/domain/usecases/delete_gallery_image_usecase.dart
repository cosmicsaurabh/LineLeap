import 'package:flutter_scribble/domain/entities/generated_image.dart';
import 'package:flutter_scribble/domain/repositories/gallery_repository.dart';

class DeleteGalleryImageUseCase {
  final GalleryRepository repository;

  DeleteGalleryImageUseCase(this.repository);

  Future<void> call(GeneratedImage image) async {
    await repository.deleteGalleryImage(image);
  }
}
