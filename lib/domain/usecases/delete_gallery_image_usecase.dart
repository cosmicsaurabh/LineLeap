import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';

class DeleteGalleryImageUseCase {
  final GalleryRepository repository;

  DeleteGalleryImageUseCase(this.repository);

  Future<void> call(GeneratedImage image) async {
    await repository.deleteGalleryImage(image);
  }
}
