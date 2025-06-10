import 'dart:developer';

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
    final model = box.values.firstWhere(
      (e) => e.filePath == image.filePath && e.timestamp == image.timestamp,
      orElse: () => throw Exception('Image not found'),
    );
    await box.delete(model.key);
  }
}
