// lib/domain/repositories/image_repository.dart
import 'dart:typed_data';

abstract class ImageRepository {
  Future<String> saveImage(Uint8List imageBytes);
  Future<Uint8List> getImageBytes(String storagePath);
}
