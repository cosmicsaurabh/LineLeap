import 'package:lineleap/data/repositories/image_save_load_delete_repository_impl.dart';

class DeleteImagebytesFromPathUseCase {
  final ImageSaveLoadDeleteRepositoryImpl imageSaveLoadDeleteRepository;

  DeleteImagebytesFromPathUseCase({
    required this.imageSaveLoadDeleteRepository,
  });

  Future<void> call(String imagePath) async {
    return await imageSaveLoadDeleteRepository.deleteImageFromPath(imagePath);
  }
}
