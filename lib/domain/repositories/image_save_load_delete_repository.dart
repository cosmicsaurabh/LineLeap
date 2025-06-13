import 'dart:typed_data';

abstract class ImageSaveLoadDeleteRepository {
  Future<String> saveImageBytesReturnPath(Uint8List imageBytes);
  Future<Uint8List> getImageBytesFromPath(String storagePath);
  Future<void> deleteImageFromPath(String storagePath);
}
