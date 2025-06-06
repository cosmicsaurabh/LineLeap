// File: lib/domain/usecases/generate_image_usecase.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_scribble/data/remote/ai_horde_api.dart';

class GenerateImageUseCase {
  final AIHordeAPI api;

  GenerateImageUseCase(this.api);

  Future<String?> generateImageFromSketch(
    Uint8List sketchBytes,
    String prompt,
  ) async {
    final base64Image = base64Encode(sketchBytes);
    final jobId = await api.submitSketchJob(base64Image, prompt);
    if (jobId == null) return null;

    return await api.pollForResult(jobId);
  }
}
