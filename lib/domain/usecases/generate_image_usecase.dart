// File: lib/domain/usecases/generate_image_usecase.dart

import 'dart:typed_data';
import 'package:flutter_scribble/data/remote/replicate_api.dart';

class GenerateImageUseCase {
  final ReplicateAPI api;

  GenerateImageUseCase(this.api);

  Future<Uint8List?> generateFromSketch(Uint8List sketch, String prompt) async {
    final getUrl = await api.generateImageFromSketch(sketch, prompt);
    if (getUrl == null) return null;

    // Simple polling/waiting could be added here if needed
    await Future.delayed(const Duration(seconds: 10));
    return await api.fetchResultImage(getUrl);
  }
}
