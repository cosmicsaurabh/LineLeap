import 'dart:typed_data';

import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';

class SaveImagebytesReturnPathUseCase {
  final ImageSaveLoadRepositoryImpl imageRepository;

  SaveImagebytesReturnPathUseCase(this.imageRepository);

  Future<String> call(Uint8List imageBytes) async {
    return await imageRepository.saveImageBytesReturnPath(imageBytes);
  }
}
