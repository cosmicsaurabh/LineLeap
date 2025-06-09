import '../entities/generated_image.dart';

abstract class GalleryRepository {
  Future<List<GeneratedImage>> getGalleryImages();
  Future<void> deleteGalleryImage(GeneratedImage image);
}
