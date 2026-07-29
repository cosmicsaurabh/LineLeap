import 'package:flutter/material.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/usecases/get_scribble_transformations_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/delete_scribbletransformation_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/save_scribble_transformation_to_history_usecase.dart';

class GalleryNotifier extends ChangeNotifier {
  // Use cases (Gallery operations like loading, saving, deleting whole ScribbleTransformation Objects)
  final GetScribbleTransformationsFromHistoryUseCase getGalleryImagesUseCase;
  final SaveScribbleTransformationToHistoryUseCase saveImageToGalleryUseCase;
  final DeleteScribbleTransformationFromHistoryUseCase
  deleteGalleryImageUseCase;

  List<ScribbleTransformation> _scribbleTransformations = [];
  bool _isLoading = false;
  String? _loadError;
  String? _operationError;

  List<ScribbleTransformation> get scribbleTransformations =>
      _scribbleTransformations;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String? get operationError => _operationError;

  /// Kept for callers that have not yet moved to the operation-specific state.
  String? get error => _operationError ?? _loadError;

  GalleryNotifier({
    required this.getGalleryImagesUseCase,
    required this.deleteGalleryImageUseCase,
    required this.saveImageToGalleryUseCase,
  });

  Future<bool> saveToHistory({
    required String scribblePath,
    required String generatedPath,
    required String prompt,
    required String timestamp,
  }) async {
    _operationError = null;
    notifyListeners();

    try {
      final generatedImage = ScribbleTransformation(
        generatedImagePath: generatedPath,
        scribbleImagePath: scribblePath,
        prompt: prompt,
        timestamp: timestamp,
      );
      await saveImageToGalleryUseCase(generatedImage);

      _scribbleTransformations.insert(0, generatedImage);
      _operationError = null;
      notifyListeners();
      return true;
    } catch (_) {
      _operationError =
          "Couldn't add this image to History. It's still in the queue—try again.";
      notifyListeners();
      return false;
    }
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _loadError = null;
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
      _loadError = null;
    } catch (_) {
      _loadError =
          "Couldn't load History. Your saved images haven't been changed—try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteImage(
    ScribbleTransformation selectedScribbleTransformation,
  ) async {
    _operationError = null;
    notifyListeners();

    try {
      await deleteGalleryImageUseCase(selectedScribbleTransformation);
      _scribbleTransformations.remove(selectedScribbleTransformation);
      _operationError = null;
      notifyListeners();
      return true;
    } catch (_) {
      _operationError =
          "Couldn't delete this image. It's still in History—try again.";
      notifyListeners();
      return false;
    }
  }
}
