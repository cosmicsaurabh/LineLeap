import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImageDeviceInteractionService {
  Future<String> saveImageToDevice(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$fileName.png';
    final file = File(imagePath);
    await file.writeAsBytes(imageBytes);
    return imagePath;
  }

  Future<Uint8List> getImageFromDevice(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    throw Exception('Image not found');
  }

  Future<void> deleteImageFromDevice(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
