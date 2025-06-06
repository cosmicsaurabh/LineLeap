import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ImageUtils {
  static Future<Uint8List?> capturePng(GlobalKey globalKey) async {
    try {
      final boundary =
          globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return null;
      final pngBytes = byteData.buffer.asUint8List();
      // debugPrint(
      //   "PNG header: ${pngBytes.sublist(0, 8)}",
      // );
      return pngBytes;
    } catch (e) {
      debugPrint("Error capturing PNG: $e");
      return null;
    }
  }
}
