import 'dart:typed_data';

import 'package:lineleap/domain/repositories/image_generation_repo.dart';

class GenerateTransformationfromscribble {
  final ImageGenerationRepository repository;

  GenerateTransformationfromscribble(this.repository);

  Future<String?> call(Uint8List sketchBytes, String prompt) {
    return repository.generateImageFromSketch(sketchBytes, prompt);
  }
}
