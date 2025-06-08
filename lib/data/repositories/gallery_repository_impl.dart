import 'package:flutter_scribble/domain/entities/generated_image.dart';
import 'package:flutter_scribble/domain/repositories/gallery_repository.dart';
import 'package:hive/hive.dart';
import '../models/generated_image_model.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  final Box<GeneratedImageModel> box;

  GalleryRepositoryImpl(this.box);

  @override
  Future<void> saveImage(GeneratedImage image) async {
    final model = GeneratedImageModel.fromEntity(image);
    await box.add(model);
  }

  @override
  Future<List<GeneratedImage>> getImages() async {
    return box.values.map((e) => e.toEntity()).toList();
  }
}
