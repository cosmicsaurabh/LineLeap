import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/usecases/get_gallery_images_usecase.dart';
import 'package:lineleap/domain/usecases/delete_gallery_image_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_usecase.dart';
import 'package:lineleap/presentation/models/gallery_image_presentation.dart';

class GalleryNotifier extends ChangeNotifier {
  final GetGalleryImagesUseCase getGalleryImagesUseCase;
  final DeleteGalleryImageUseCase deleteGalleryImageUseCase;
  final SaveImageUseCase saveImageUseCase;

  List<GalleryImagePresentation> _images = [];
  bool _isLoading = false;
  String? _error;

  List<GalleryImagePresentation> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GalleryNotifier({
    required this.getGalleryImagesUseCase,
    required this.deleteGalleryImageUseCase,
    required this.saveImageUseCase,
  }) {
    loadImages();
  }
  Future<void> saveGeneratedImage(
    Uint8List scribbleBytes,
    Uint8List generatedBytes,
    String prompt,
  ) async {
    final savedImage = await saveImageUseCase(
      scribbleBytes,
      generatedBytes,
      prompt,
    );

    // Create presentation model with both entity and cached bytes
    _images.insert(
      0,
      GalleryImagePresentation(
        imageHiveObject: savedImage,
        cachedScribbleBytes: scribbleBytes,
        cachedGeneratedBytes: generatedBytes,
      ),
    );

    notifyListeners();
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final generatedImages = await getGalleryImagesUseCase();
      _images =
          generatedImages
              .map((img) => GalleryImagePresentation(imageHiveObject: img))
              .toList();
    } catch (e) {
      _error = 'Failed to load images';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteImage(GalleryImagePresentation image) async {
    try {
      _images.remove(image);
      notifyListeners();
      // After removing the image from the list, any cached bytes will be eligible for garbage collection.
      await deleteGalleryImageUseCase(image.imageHiveObject);
    } catch (e) {
      _error = 'Failed to delete image';
      notifyListeners();
    }
  }
}
