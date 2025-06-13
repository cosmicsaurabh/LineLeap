import 'dart:developer';
import 'package:lineleap/core/service/image_device_interaction_service.dart';
import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';
import 'package:hive/hive.dart';
import '../models/scribble_transformation_hive_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final Box<ScribbleTransformationHive> box;
  final ImageDeviceInteractionService _imageDeviceInteractionService;

  HistoryRepositoryImpl(this.box, this._imageDeviceInteractionService);

  @override
  Future<List<ScribbleTransformation>>
  getScribbleTransformationsFromHistory() async {
    log('History box name: ${box.name}, total images: ${box.length}');
    log('Fetching history images from Hive');
    if (box.isEmpty) {
      log('No images found in history');
      return [];
    }
    return box.values.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> deleteScribbleTransformationFromHistory(
    ScribbleTransformation scribbleTransformation,
  ) async {
    // Find and delete entry from Hive database
    final model = box.values.firstWhere(
      (e) =>
          e.generatedImagePathHive ==
              scribbleTransformation.generatedImagePath &&
          e.createdAtHive == scribbleTransformation.timestamp,
      orElse: () => throw Exception('Image not found'),
    );
    await box.delete(model.key);

    // Delete the actual image files from device storage
    try {
      _imageDeviceInteractionService.deleteImageFromDevice(
        scribbleTransformation.generatedImagePath,
      );
      _imageDeviceInteractionService.deleteImageFromDevice(
        scribbleTransformation.scribbleImagePath,
      );
      log('Image files deleted successfully');
    } catch (e) {
      log('Error deleting image files: $e');
    }
  }

  @override
  Future<void> saveScribbleTransformationToHistory(
    ScribbleTransformation scribbleTransformation,
  ) async {
    // Convert to model and save to Hive(we already have the image files saved)
    final model = ScribbleTransformationHive.fromEntity(scribbleTransformation);
    await box.add(model);
    log('Image saved to history: ${scribbleTransformation.prompt}');
  }
}
