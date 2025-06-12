import 'dart:typed_data';

import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';
import 'package:lineleap/domain/entities/generated_image.dart';

class SaveImageUseCase {
  final ImageSaveLoadRepositoryImpl imageRepository;

  SaveImageUseCase(this.imageRepository);

  Future<GeneratedImage> call(
    Uint8List scribbleImageBytes,
    Uint8List generatedImageBytes,
    String prompt,
  ) async {
    return await imageRepository.saveGeneratedImage(
      scribbleImageBytes,
      generatedImageBytes,
      prompt,
    );
  }
}
