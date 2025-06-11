import 'dart:developer';
import 'dart:io';

import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';
import 'package:hive/hive.dart';
import '../models/generated_image_model.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final Box<GeneratedImageModel> box;

  GalleryRepositoryImpl(this.box);

  @override
  Future<List<GeneratedImage>> getGalleryImages() async {
    log('Gallery box name: ${box.name}, total images: ${box.length}');

    log('Fetching gallery images from Hive');
    if (box.isEmpty) {
      log('No images found in gallery');
      return [];
    }

    return box.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> deleteGalleryImage(GeneratedImage image) async {
    // Find and delete entry from Hive database
    final model = box.values.firstWhere(
      (e) =>
          e.generatedImageFilePath == image.generatedImageFilePath &&
          e.timestamp == image.timestamp,
      orElse: () => throw Exception('Image not found'),
    );
    await box.delete(model.key);

    // Delete the actual image files from device storage
    try {
      final generatedImageFile = File(image.generatedImageFilePath);
      final scribbleImageFile = File(image.scribbleImageFilePath);

      if (await generatedImageFile.exists()) {
        await generatedImageFile.delete();
      }

      if (await scribbleImageFile.exists()) {
        await scribbleImageFile.delete();
      }

      log('Image files deleted successfully');
    } catch (e) {
      log('Error deleting image files: $e');
    }
  }
}
