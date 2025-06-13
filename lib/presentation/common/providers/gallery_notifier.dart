import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/usecases/get_scribbleTransformations_from_history.dart';
import 'package:lineleap/domain/usecases/delete_scribbleTransformation_from_history.dart';
import 'package:lineleap/domain/usecases/save_scribbleTransformation_to_history.dart';
import 'package:lineleap/domain/usecases/save_imageBytes_return_path.dart';

class GalleryNotifier extends ChangeNotifier {
  final GetScribbleTransformationsFromHistory getGalleryImagesUseCase;
  final DeleteScribbleTransformationFromHistory deleteGalleryImageUseCase;
  final SaveImagebytesReturnPathUseCase saveImageUseCase;
  final SaveScribbleTransformationToHistoryUseCase saveImageToGalleryUseCase;
  List<ScribbleTransformation> _images = [];
  bool _isLoading = false;
  String? _error;

  List<ScribbleTransformation> get images => _images;
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

    return savedImagePath;
  }

  Future<bool> saveToHistory({
    required String scribblePath,
    required String generatedPath,
    required String prompt,
    required String timestamp,
  }) async {
    // Implement the logic to save the image paths and metadata to history
    try {
      final generatedImage = ScribbleTransformation(
        generatedImagePath: generatedPath,
        scribbleImagePath: scribblePath,
        prompt: prompt,
        timestamp: timestamp,
      );
      await saveImageToGalleryUseCase(generatedImage);

      _images.insert(0, generatedImage);

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save image r45454to gallery';
      notifyListeners();
      return false;
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
                (img) => ScribbleTransformation(
                  generatedImagePath: img.generatedImagePath,
                  scribbleImagePath: img.scribbleImagePath,
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

  Future<void> deleteImage(ScribbleTransformation image) async {
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
