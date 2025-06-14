import 'dart:typed_data';

import 'package:lineleap/domain/repositories/image_generation_repo.dart';

class GenerateTransformationfromscribbleUseCase {
  final ImageGenerationRepository repository;

  GenerateTransformationfromscribbleUseCase(this.repository);

  Future<String?> call(Uint8List sketchBytes, String prompt) {
    return repository.generateImageFromSketch(sketchBytes, prompt);
  }
}
