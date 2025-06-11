// lib/domain/repositories/image_repository.dart
import 'dart:typed_data';
import 'package:lineleap/domain/entities/generated_image.dart';

abstract class ImageRepository {
  Future<GeneratedImage> saveGeneratedImage(
    Uint8List scribbleImageBytes,
    Uint8List generatedImageBytes,
    String prompt,
  );
  Future<Uint8List> getImageBytes(String storagePath);
}
