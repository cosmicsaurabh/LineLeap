import 'dart:developer';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/domain/repositories/image_save_load_repository.dart';

class ImageSaveLoadRepositoryImpl implements ImageSaveLoadRepository {
  final ImageStorageService storageService;

  ImageSaveLoadRepositoryImpl(this.storageService);

  @override
  Future<String> saveImage(Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageFileName = 'image_$timestamp';

      // Save to device storage
      final savedImagePath = await storageService.saveImage(
        imageBytes,
        imageFileName,
      );
      return savedImagePath;
    } catch (e) {
      log('Error saving image: $e');
      // Re-throw the exception to handle it in the calling code
      rethrow;
    }
  }

  @override
  Future<Uint8List> getImageBytes(String storagePath) async {
    return await storageService.getImage(storagePath);
  }
}
