import 'package:lineleap/data/repositories/image_save_load_delete_repository_impl.dart';

class DeleteImagebytesFromPathUseCase {
  final ImageSaveLoadDeleteRepositoryImpl imageRepository;

  DeleteImagebytesFromPathUseCase(this.imageRepository);

  Future<void> call(String imagePath) async {
    return await imageRepository.deleteImageFromPath(imagePath);
  }
}
