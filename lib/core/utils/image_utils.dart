import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ImageUtils {
  static Future<Uint8List?> capturePng(GlobalKey globalKey) async {
    ui.Image? capturedImage;
    ui.Image? compositedImage;
    ui.Picture? compositePicture;

    try {
      final binding = WidgetsBinding.instance;
      final schedulerPhase = binding.schedulerPhase;
      final paintIsPending =
          schedulerPhase == SchedulerPhase.transientCallbacks ||
          schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
          schedulerPhase == SchedulerPhase.persistentCallbacks;
      if (binding.hasScheduledFrame || paintIsPending) {
        await binding.endOfFrame;
      }

      final renderObject = globalKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary ||
          !renderObject.attached ||
          !renderObject.hasSize ||
          renderObject.size.isEmpty) {
        debugPrint('Unable to capture PNG: canvas is not ready.');
        return null;
      }

      capturedImage = await renderObject.toImage(pixelRatio: 3.0);
      final imageBounds = ui.Rect.fromLTWH(
        0,
        0,
        capturedImage.width.toDouble(),
        capturedImage.height.toDouble(),
      );
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder, imageBounds)
        ..drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src)
        ..drawImage(capturedImage, ui.Offset.zero, ui.Paint());
      compositePicture = recorder.endRecording();
      compositedImage = await compositePicture.toImage(
        capturedImage.width,
        capturedImage.height,
      );
      compositePicture.dispose();
      compositePicture = null;
      capturedImage.dispose();
      capturedImage = null;

      final byteData = await compositedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        debugPrint('Unable to capture PNG: encoding returned no bytes.');
        return null;
      }
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } catch (error, stackTrace) {
      debugPrint('Error capturing PNG: $error\n$stackTrace');
      return null;
    } finally {
      compositedImage?.dispose();
      compositePicture?.dispose();
      capturedImage?.dispose();
    }
  }
}
