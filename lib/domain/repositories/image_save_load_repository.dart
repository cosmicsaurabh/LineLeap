import 'dart:typed_data';

abstract class ImageSaveLoadRepository {
  Future<String> saveImageBytesReturnPath(Uint8List imageBytes);
  Future<Uint8List> getImageBytesFromPath(String storagePath);
}
