import 'dart:typed_data';
import 'package:lineleap/domain/repositories/image_generation_repo.dart';

import '../remote/ai_horde_api.dart';
import 'dart:convert';

class ImageGenerationRepositoryImpl implements ImageGenerationRepository {
  final AIHordeAPI api;

  ImageGenerationRepositoryImpl(this.api);

  @override
  Future<String?> generateImageFromSketch(
    Uint8List sketchBytes,
    String prompt,
  ) async {
    try {
      final base64Image = base64Encode(sketchBytes);
      final jobId = await api.submitSketchJob(base64Image, prompt);
      return await api.pollForResult(jobId);
    } catch (_) {
      return null;
    }
  }
}
