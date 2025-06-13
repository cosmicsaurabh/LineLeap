import 'dart:developer';
import 'dart:io';

import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/gallery_repository.dart';
import 'package:hive/hive.dart';
import '../models/scribble_transformation_hive_model.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final Box<ScribbleTransformationHive> box;

  GalleryRepositoryImpl(this.box);

  @override
  Future<List<ScribbleTransformation>> getGalleryImages() async {
    log('Gallery box name: ${box.name}, total images: ${box.length}');

    log('Fetching gallery images from Hive');
    if (box.isEmpty) {
      log('No images found in gallery');
      return [];
    }

    return box.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> deleteGalleryImage(ScribbleTransformation image) async {
    // Find and delete entry from Hive database
    final model = box.values.firstWhere(
      (e) =>
          e.generatedImagePathHive == image.generatedImagePath &&
          e.createdAtHive == image.timestamp,
      orElse: () => throw Exception('Image not found'),
    );
    await box.delete(model.key);

    // Delete the actual image files from device storage
    try {
      final generatedImageFile = File(image.generatedImagePath);
      final scribbleImageFile = File(image.scribbleImagePath);

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

  @override
  Future<void> saveToGallery(ScribbleTransformation image) async {
    // Convert to model and save to Hive
    final model = ScribbleTransformationHive.fromEntity(image);
    await box.add(model);
    log('Image saved to gallery: ${image.prompt}');
  }
}
