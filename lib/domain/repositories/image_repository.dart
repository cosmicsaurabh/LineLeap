// lib/domain/repositories/image_repository.dart
import 'dart:typed_data';
import 'package:flutter_scribble/domain/entities/generated_image.dart';

abstract class ImageRepository {
  Future<GeneratedImage> saveGeneratedImage(
    Uint8List imageBytes,
    String prompt,
  );
  Future<Uint8List> getImageBytes(String storagePath);
}
