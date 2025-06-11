import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lineleap/domain/usecases/get_gallery_images_usecase.dart';
import 'package:lineleap/domain/usecases/delete_gallery_image_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_usecase.dart';
import '../../../domain/entities/generated_image.dart';

class GalleryNotifier extends ChangeNotifier {
  final GetGalleryImagesUseCase getGalleryImagesUseCase;
  final DeleteGalleryImageUseCase deleteGalleryImageUseCase;
  final SaveImageUseCase saveImageUseCase;

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
  }) {
    loadImages();
  }
  Future<void> saveGeneratedImage(
    Uint8List scribbleBytes,
    Uint8List generatedBytes,
    String prompt,
  ) async {
    await saveImageUseCase(scribbleBytes, generatedBytes, prompt);
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _images = await getGalleryImagesUseCase();
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
      await deleteGalleryImageUseCase(image);
    } catch (e) {
      _error = 'Failed to delete image';
      notifyListeners();
    }
  }
}
