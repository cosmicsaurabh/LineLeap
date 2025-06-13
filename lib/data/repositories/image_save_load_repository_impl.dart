// lib/data/repositories/image_repository_impl.dart
import 'dart:developer';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/data/models/generated_image_model.dart';
import 'package:lineleap/domain/repositories/image_repository.dart';
import 'package:hive/hive.dart';

class ImageSaveLoadRepositoryImpl implements ImageRepository {
  final ImageStorageService _storageService;
  final Box<GeneratedImageModel> _imageBox;

  ImageSaveLoadRepositoryImpl(this._storageService, this._imageBox);

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
      //   generatedImageFilePath: savedImagePath,
      //   scribbleImageFilePath: scribbleStoragePath,
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
