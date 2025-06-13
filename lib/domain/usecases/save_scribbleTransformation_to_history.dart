import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';

class SaveScribbletransformationToHistory {
  final GalleryRepository _galleryRepository;

  SaveScribbletransformationToHistory(this._galleryRepository);

  Future<void> call(ScribbleTransformation image) async {
    await _galleryRepository.saveToGallery(image);
  }
}
