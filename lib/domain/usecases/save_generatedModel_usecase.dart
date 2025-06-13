import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';

class SaveGeneratedModelUseCase {
  final GalleryRepository _galleryRepository;

  SaveGeneratedModelUseCase(this._galleryRepository);

  Future<void> call(GeneratedImage image) async {
    await _galleryRepository.saveToGallery(image);
  }
}
