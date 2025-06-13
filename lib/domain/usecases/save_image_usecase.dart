import 'dart:typed_data';

import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';

class SaveImageUseCase {
  final ImageSaveLoadRepositoryImpl imageRepository;

  SaveImageUseCase(this.imageRepository);

  Future<String> call(Uint8List imageBytes) async {
    return await imageRepository.saveImage(imageBytes);
  }
}
