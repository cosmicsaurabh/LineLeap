import 'dart:typed_data';

abstract class ImageGenerationRepository {
  Future<String?> generateImageFromSketch(Uint8List sketchBytes, String prompt);
}
