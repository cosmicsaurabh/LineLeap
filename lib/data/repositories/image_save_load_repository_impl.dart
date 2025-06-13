// lib/data/repositories/image_repository_impl.dart
import 'dart:developer';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/domain/repositories/image_save_load_repository.dart';

class ImageSaveLoadRepositoryImpl implements ImageSaveLoadRepository {
  final ImageStorageService _storageService;

  ImageSaveLoadRepositoryImpl(this._storageService);

  @override
  Future<String> saveImage(Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageFileName = 'image_$timestamp';

      // Save to device storage
      final savedImagePath = await _storageService.saveImage(
        imageBytes,
        imageFileName,
      );

      // // Save reference to Hive
      // final image = GeneratedImage(
      //   generatedImagePath: savedImagePath,
      //   scribbleImagePath: scribbleStoragePath,
      //   prompt: prompt,
      //   timestamp: DateTime.now().toIso8601String(),
      // );

      // await _imageBox.add(GeneratedImageModel.fromEntity(image));
      // log('Saving image with prompt: $prompt');
      // log('Saved to path: $generatedImageStoragePath');
      // log(
      //   'Image saved in Hive box: ${_imageBox.name}, total: ${_imageBox.length}',
      // );

      return savedImagePath;
    } catch (e) {
      log('Error saving image: $e');
      // Re-throw the exception to handle it in the calling code
      rethrow;
    }
  }

  @override
  Future<Uint8List> getImageBytes(String storagePath) async {
    return await _storageService.getImage(storagePath);
  }
}
