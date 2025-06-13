import 'dart:developer';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_device_interaction_service.dart';
import 'package:lineleap/domain/repositories/image_save_load_delete_repository.dart';

class ImageSaveLoadDeleteRepositoryImpl
    implements ImageSaveLoadDeleteRepository {
  final ImageDeviceInteractionService _imageDeviceInteractionService;

  ImageSaveLoadDeleteRepositoryImpl(this._imageDeviceInteractionService);

  @override
  Future<String> saveImageBytesReturnPath(Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageFileName = 'image_$timestamp';

      // Save to device storage
      final savedImagePath = await _imageDeviceInteractionService
          .saveImageToDevice(imageBytes, imageFileName);
      return savedImagePath;
    } catch (e) {
      log('Error saving image: $e');
      // Re-throw the exception to handle it in the calling code
      rethrow;
    }
  }

  @override
  Future<Uint8List> getImageBytesFromPath(String storagePath) async {
    return await _imageDeviceInteractionService.getImageFromDevice(storagePath);
  }

  @override
  Future<void> deleteImageFromPath(String storagePath) async {
    try {
      await _imageDeviceInteractionService.deleteImageFromDevice(storagePath);
      log('Image deleted successfully from path: $storagePath');
    } catch (e) {
      log('Error deleting image from path $storagePath: $e');
      // Re-throw the exception to handle it in the calling code
      rethrow;
    }
  }
}
