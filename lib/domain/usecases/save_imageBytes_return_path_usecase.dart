import 'dart:typed_data';

import 'package:lineleap/domain/repositories/image_save_load_delete_repository.dart';

class SaveImagebytesReturnPathUseCase {
  final ImageSaveLoadDeleteRepository imageSaveLoadDeleteRepository;

  SaveImagebytesReturnPathUseCase({
    required this.imageSaveLoadDeleteRepository,
  });

  Future<String> call(Uint8List imageBytes) async {
    return await imageSaveLoadDeleteRepository.saveImageBytesReturnPath(
      imageBytes,
    );
  }
}
