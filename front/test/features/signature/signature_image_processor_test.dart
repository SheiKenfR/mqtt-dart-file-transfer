import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:poc_sign/features/signature/infrastructure/signature_image_processor.dart';

Uint8List _createTestPng({
  int width = 400,
  int height = 300,
  required void Function(img.Image canvas) draw,
}) {
  final canvas = img.Image(width: width, height: height, numChannels: 4);
  draw(canvas);
  return Uint8List.fromList(img.encodePng(canvas));
}

Uint8List _createHorizontalStroke() {
  return _createTestPng(draw: (canvas) {
    for (int x = 50; x < 350; x++) {
      for (int dy = -2; dy <= 2; dy++) {
        canvas.setPixelRgba(x, 150 + dy, 0, 0, 0, 255);
      }
    }
  });
}

Uint8List _createVerticalStroke() {
  return _createTestPng(draw: (canvas) {
    for (int y = 20; y < 280; y++) {
      for (int dx = -2; dx <= 2; dx++) {
        canvas.setPixelRgba(200 + dx, y, 0, 0, 0, 255);
      }
    }
  });
}

Uint8List _createEdgeStroke() {
  return _createTestPng(draw: (canvas) {
    for (int x = 0; x < 10; x++) {
      for (int y = 0; y < 10; y++) {
        canvas.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  });
}

Uint8List _createEmptyPng() {
  return _createTestPng(draw: (_) {});
}

void main() {
  late SignatureImageProcessor processor;

  setUp(() {
    processor = SignatureImageProcessor();
  });

  test('throws on empty signature (no visible pixels)', () {
    final emptyPng = _createEmptyPng();

    expect(
      () => processor.processSignature(emptyPng),
      throwsA(isA<StateError>()),
    );
  });

  test('throws on invalid PNG bytes', () {
    final garbage = Uint8List.fromList([0, 1, 2, 3]);

    expect(
      () => processor.processSignature(garbage),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('output is exactly 256x256', () async {
    final stroke = _createHorizontalStroke();
    final result = await processor.processSignature(stroke);
    final decoded = img.decodePng(result)!;

    expect(decoded.width, 256);
    expect(decoded.height, 256);
  });

  test('horizontal stroke is not stretched', () async {
    final stroke = _createHorizontalStroke();
    final result = await processor.processSignature(stroke);
    final decoded = img.decodePng(result)!;

    int minY = decoded.height, maxY = 0;
    int minX = decoded.width, maxX = 0;
    for (int y = 0; y < decoded.height; y++) {
      for (int x = 0; x < decoded.width; x++) {
        if (decoded.getPixel(x, y).a > 10) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }

    final drawWidth = maxX - minX + 1;
    final drawHeight = maxY - minY + 1;

    expect(drawWidth, greaterThan(drawHeight),
        reason: 'Horizontal stroke must remain wider than tall');
  });

  test('vertical stroke is not stretched', () async {
    final stroke = _createVerticalStroke();
    final result = await processor.processSignature(stroke);
    final decoded = img.decodePng(result)!;

    int minY = decoded.height, maxY = 0;
    int minX = decoded.width, maxX = 0;
    for (int y = 0; y < decoded.height; y++) {
      for (int x = 0; x < decoded.width; x++) {
        if (decoded.getPixel(x, y).a > 10) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }

    final drawWidth = maxX - minX + 1;
    final drawHeight = maxY - minY + 1;

    expect(drawHeight, greaterThan(drawWidth),
        reason: 'Vertical stroke must remain taller than wide');
  });

  test('crop handles strokes near edges', () async {
    final stroke = _createEdgeStroke();
    final result = await processor.processSignature(stroke);
    final decoded = img.decodePng(result)!;

    expect(decoded.width, 256);
    expect(decoded.height, 256);

    bool hasVisiblePixels = false;
    for (int y = 0; y < decoded.height && !hasVisiblePixels; y++) {
      for (int x = 0; x < decoded.width && !hasVisiblePixels; x++) {
        if (decoded.getPixel(x, y).a > 10) {
          hasVisiblePixels = true;
        }
      }
    }
    expect(hasVisiblePixels, isTrue);
  });

  test('transparent background is preserved', () async {
    final stroke = _createHorizontalStroke();
    final result = await processor.processSignature(stroke);
    final decoded = img.decodePng(result)!;

    final cornerPixel = decoded.getPixel(0, 0);
    expect(cornerPixel.a.toInt(), 0,
        reason: 'Corners should be fully transparent');
  });

  test('custom target size produces correct dimensions', () async {
    final stroke = _createHorizontalStroke();
    final result = await processor.processSignature(stroke, targetSize: 128);
    final decoded = img.decodePng(result)!;

    expect(decoded.width, 128);
    expect(decoded.height, 128);
  });
}
