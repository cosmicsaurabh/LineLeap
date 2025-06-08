import '../entities/generated_image.dart';

abstract class GalleryRepository {
  Future<void> saveImage(GeneratedImage image);
  Future<List<GeneratedImage>> getImages();
}
