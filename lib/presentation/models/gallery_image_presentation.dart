import 'dart:typed_data';
import 'package:lineleap/domain/entities/generated_image.dart';

class GalleryImagePresentation {
  final GeneratedImage imageHiveObject;
  final Uint8List? cachedScribbleBytes;
  final Uint8List? cachedGeneratedBytes;

  GalleryImagePresentation({
    required this.imageHiveObject,
    this.cachedScribbleBytes,
    this.cachedGeneratedBytes,
  });
}
