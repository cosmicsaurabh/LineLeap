import '../entities/generated_image.dart';
import '../repositories/gallery_repository.dart';

class SaveImageUseCase {
  final GalleryRepository repository;

  SaveImageUseCase(this.repository);

  Future<void> call(GeneratedImage image) => repository.saveImage(image);
}
