import 'package:flutter/material.dart';
import 'package:flutter_scribble/domain/usecases/get_image_usecase.dart';
import '../../../domain/entities/generated_image.dart';

class GalleryNotifier extends ChangeNotifier {
  final GetImagesUseCase getImagesUseCase;

  List<GeneratedImage> _images = [];
  bool _isLoading = true;

  List<GeneratedImage> get images => _images;
  bool get isLoading => _isLoading;

  GalleryNotifier({required this.getImagesUseCase}) {
    loadImages();
  }

  Future<void> loadImages() async {
    _isLoading = true;
    notifyListeners();

    _images = await getImagesUseCase();
    _isLoading = false;
    notifyListeners();
  }
}
