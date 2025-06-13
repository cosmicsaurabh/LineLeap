import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:lineleap/domain/usecases/get_gallery_images_usecase.dart';
import 'package:lineleap/domain/usecases/delete_gallery_image_usecase.dart';
import 'package:lineleap/domain/usecases/save_generatedModel_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_usecase.dart';

class GalleryNotifier extends ChangeNotifier {
  final GetGalleryImagesUseCase getGalleryImagesUseCase;
  final DeleteGalleryImageUseCase deleteGalleryImageUseCase;
  final SaveImageUseCase saveImageUseCase;
  final SaveGeneratedModelUseCase saveImageToGalleryUseCase;
  List<GeneratedImage> _images = [];
  bool _isLoading = false;
  String? _error;

  List<GeneratedImage> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GalleryNotifier({
    required this.getGalleryImagesUseCase,
    required this.deleteGalleryImageUseCase,
    required this.saveImageUseCase,
    required this.saveImageToGalleryUseCase,
  }) {
    loadImages();
  }
  Future<String> saveImage(Uint8List imageBytes) async {
    final savedImagePath = await saveImageUseCase(imageBytes);

    // // Create presentation model with both entity and cached bytes
    // _images.insert(
    //   0,
    //   GalleryImagePresentation(
    //     imageHiveObject: savedImage,
    //     cachedScribbleBytes: scribbleBytes,
    //     cachedGeneratedBytes: generatedBytes,
    //   ),
    // );
    return savedImagePath;
  }

  Future<void> saveToHistory({
    required String scribblePath,
    required String generatedPath,
    required String prompt,
    required String timestamp,
  }) async {
    // Implement the logic to save the image paths and metadata to history
    try {
      final generatedImage = GeneratedImage(
        generatedImageFilePath: generatedPath,
        scribbleImageFilePath: scribblePath,
        prompt: prompt,
        timestamp: timestamp,
      );
      await saveImageToGalleryUseCase(generatedImage);

      _images.insert(0, generatedImage);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save image r45454to gallery';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final generatedImages = await getGalleryImagesUseCase();
      _images =
          generatedImages
              .map(
                (img) => GeneratedImage(
                  generatedImageFilePath: img.generatedImageFilePath,
                  scribbleImageFilePath: img.scribbleImageFilePath,
                  prompt: img.prompt,
                  timestamp: img.timestamp,
                ),
              )
              .toList();
    } catch (e) {
      _error = 'Failed to load images';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteImage(GeneratedImage image) async {
    try {
      _images.remove(image);
      notifyListeners();
      // After removing the image from the list, any cached bytes will be eligible for garbage collection.
      await deleteGalleryImageUseCase(image);
    } catch (e) {
      _error = 'Failed to delete image';
      notifyListeners();
    }
  }
}
