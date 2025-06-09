import '../entities/generated_image.dart';
import '../repositories/gallery_repository.dart';

class GetGalleryImagesUseCase {
  final GalleryRepository repository;

  GetGalleryImagesUseCase(this.repository);

  Future<List<GeneratedImage>> call() => repository.getGalleryImages();
}
