import '../entities/generated_image.dart';
import '../repositories/gallery_repository.dart';

class GetImagesUseCase {
  final GalleryRepository repository;

  GetImagesUseCase(this.repository);

  Future<List<GeneratedImage>> call() => repository.getImages();
}
