import 'dart:typed_data';

abstract class ImageSaveLoadRepository {
  Future<String> saveImage(Uint8List imageBytes);
  Future<Uint8List> getImageBytes(String storagePath);
}
