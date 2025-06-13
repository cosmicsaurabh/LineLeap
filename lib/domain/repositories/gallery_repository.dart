import '../entities/sketch_transformation.dart';

abstract class GalleryRepository {
  Future<List<ScribbleTransformation>> getGalleryImages();
  Future<void> deleteGalleryImage(ScribbleTransformation image);
  Future<void> saveToGallery(ScribbleTransformation image); // Add this method
}
