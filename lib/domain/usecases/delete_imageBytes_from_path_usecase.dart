import 'package:lineleap/domain/repositories/image_save_load_delete_repository.dart';

class DeleteImagebytesFromPathUseCase {
  final ImageSaveLoadDeleteRepository imageSaveLoadDeleteRepository;

  DeleteImagebytesFromPathUseCase({
    required this.imageSaveLoadDeleteRepository,
  });

  Future<void> call(String imagePath) async {
    return await imageSaveLoadDeleteRepository.deleteImageFromPath(imagePath);
  }
}
