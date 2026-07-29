import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/core/config/brush.dart';
import 'package:lineleap/core/utils/image_utils.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/features/scribble/scribble_drawing_area.dart';
import 'package:lineleap/theme/app_theme.dart';

void main() {
  testWidgets(
    'canvas capture uses the same opaque white background in both themes',
    (tester) async {
      final lightPng = await _captureDrawing(tester, isDark: false);
      final darkPng = await _captureDrawing(tester, isDark: true);

      final lightImage = await tester.runAsync(() => _decodePng(lightPng));
      final darkImage = await tester.runAsync(() => _decodePng(darkPng));
      if (lightImage == null || darkImage == null) {
        throw StateError('PNG decoding unexpectedly returned null.');
      }

      expect(lightImage.width, greaterThan(0));
      expect(lightImage.height, lightImage.width);
      expect(darkImage.width, lightImage.width);
      expect(darkImage.height, lightImage.height);
      final captureScale = lightImage.width / 64;
      final offStroke = (12 * captureScale).round();
      expect(_pixelAt(lightImage, 0, 0), [255, 255, 255, 255]);
      expect(_pixelAt(lightImage, offStroke, offStroke), [255, 255, 255, 255]);
      expect(_pixelAt(darkImage, 0, 0), [255, 255, 255, 255]);
      expect(_pixelAt(darkImage, offStroke, offStroke), [255, 255, 255, 255]);
      for (final logicalX in [16, 32, 48]) {
        _expectRedStrokePixel(
          lightImage,
          x: (logicalX * captureScale).round(),
          y: (32 * captureScale).round(),
        );
      }
      expect(
        _pixelAt(
          lightImage,
          (32 * captureScale).round(),
          (52 * captureScale).round(),
        ),
        [255, 255, 255, 255],
      );
      expect(_nonOpaquePixelCount(lightImage), 0);
      expect(_nonOpaquePixelCount(darkImage), 0);
      expect(darkImage.pixels, orderedEquals(lightImage.pixels));
    },
  );
}

Future<Uint8List> _captureDrawing(
  WidgetTester tester, {
  required bool isDark,
}) async {
  final paintKey = GlobalKey();
  final notifier =
      EnhancedScribbleNotifier()
        ..selectColor(const Color(0xFFB71C1C))
        ..selectBrushStyle(BrushStyle.xtraThick)
        ..startStroke(const Offset(16, 32))
        ..appendPoint(const Offset(48, 32))
        ..endStroke();
  final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 96,
            height: 96,
            child: ScribbleDrawingArea(
              notifier: notifier,
              paintKey: paintKey,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final pngBytes = await tester.runAsync(() => ImageUtils.capturePng(paintKey));
  await tester.pumpWidget(const SizedBox.shrink());
  notifier.dispose();
  if (pngBytes == null) {
    throw StateError('Canvas capture unexpectedly returned null.');
  }
  return pngBytes;
}

Future<_DecodedImage> _decodePng(Uint8List pngBytes) async {
  final codec = await ui.instantiateImageCodec(pngBytes);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        throw StateError('PNG decoding unexpectedly returned no pixels.');
      }
      final pixels = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      return (
        width: image.width,
        height: image.height,
        pixels: Uint8List.fromList(pixels),
      );
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

List<int> _pixelAt(_DecodedImage image, int x, int y) {
  final offset = (y * image.width + x) * 4;
  return image.pixels.sublist(offset, offset + 4);
}

void _expectRedStrokePixel(
  _DecodedImage image, {
  required int x,
  required int y,
}) {
  final pixel = _pixelAt(image, x, y);
  expect(pixel[0], greaterThan(150));
  expect(pixel[1], lessThan(80));
  expect(pixel[2], lessThan(80));
  expect(pixel[3], 255);
}

int _nonOpaquePixelCount(_DecodedImage image) {
  var count = 0;
  for (var index = 3; index < image.pixels.length; index += 4) {
    if (image.pixels[index] != 255) count++;
  }
  return count;
}

typedef _DecodedImage = ({int width, int height, Uint8List pixels});
