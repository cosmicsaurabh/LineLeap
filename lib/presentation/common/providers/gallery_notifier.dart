import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/usecases/get_scribbleTransformations_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/delete_scribbleTransformation_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/save_scribbleTransformation_to_history_usecase.dart';

class GalleryNotifier extends ChangeNotifier {
  // Use cases (Gallery operations like loading, saving, deleting whole ScribbleTransformation Objects)
  final GetScribbleTransformationsFromHistoryUseCase getGalleryImagesUseCase;
  final SaveScribbleTransformationToHistoryUseCase saveImageToGalleryUseCase;
  final DeleteScribbleTransformationFromHistoryUseCase
  deleteGalleryImageUseCase;

  List<ScribbleTransformation> _scribbleTransformations = [];
  bool _isLoading = false;
  String? _error;

  List<ScribbleTransformation> get scribbleTransformations =>
      _scribbleTransformations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GalleryNotifier({
    required this.getGalleryImagesUseCase,
    required this.deleteGalleryImageUseCase,
    required this.saveImageToGalleryUseCase,
  }) {
    loadImages();
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

      _scribbleTransformations.insert(0, generatedImage);

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
      _scribbleTransformations =
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
      _error = 'Failed to load scribbleTransformations';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteImage(
    ScribbleTransformation selectedScribbleTransformation,
  ) async {
    try {
      _scribbleTransformations.remove(selectedScribbleTransformation);
      notifyListeners();
      // After removing the image from the list, any cached bytes will be eligible for garbage collection.
      await deleteGalleryImageUseCase(selectedScribbleTransformation);
    } catch (e) {
      _error = 'Failed to delete image';
      notifyListeners();
    }
  }
}
