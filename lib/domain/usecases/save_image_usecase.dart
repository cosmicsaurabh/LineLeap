import 'dart:typed_data';

import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';

class SaveImageUseCase {
  final ImageSaveLoadRepositoryImpl imageRepository;

  SaveImageUseCase(this.imageRepository);

  Future<void> call(
    Uint8List scribbleImageBytes,
    Uint8List generatedImageBytes,
    String prompt,
  ) async {
    await imageRepository.saveGeneratedImage(
      scribbleImageBytes,
      generatedImageBytes,
      prompt,
    );
  }
}
