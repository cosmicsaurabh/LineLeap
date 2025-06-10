// lib/data/repositories/image_repository_impl.dart
import 'dart:developer';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/data/models/generated_image_model.dart';
import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/domain/repositories/image_repository.dart';
import 'package:hive/hive.dart';

class ImageSaveLoadRepositoryImpl implements ImageRepository {
  final ImageStorageService _storageService;
  final Box<GeneratedImageModel> _imageBox;

  ImageSaveLoadRepositoryImpl(this._storageService, this._imageBox);

  @override
  Future<GeneratedImage> saveGeneratedImage(
    Uint8List imageBytes,
    String prompt,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'image_$timestamp';

    // Save to device storage
    final storagePath = await _storageService.saveImage(imageBytes, fileName);

    // Save reference to Hive
    final image = GeneratedImage(
      filePath: storagePath,
      prompt: prompt,
      timestamp: DateTime.now(),
    );

    await _imageBox.add(GeneratedImageModel.fromEntity(image));
    log('Saving image with prompt: $prompt');
    log('Saved to path: $storagePath');
    log(
      'Image saved in Hive box: ${_imageBox.name}, total: ${_imageBox.length}',
    );

    return image;
  }

  @override
  Future<Uint8List> getImageBytes(String storagePath) async {
    return await _storageService.getImage(storagePath);
  }
}
