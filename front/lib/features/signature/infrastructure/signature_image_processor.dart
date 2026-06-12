import 'dart:typed_data';
import 'dart:math';

import 'package:image/image.dart' as img;

const int kTargetSize = 256;
const int kCropPadding = 12;
const int kAlphaThreshold = 10;

class SignatureImageProcessor {
  Future<Uint8List> processSignature(
    Uint8List rawPngBytes, {
    int targetSize = kTargetSize,
    int padding = kCropPadding,
    int alphaThreshold = kAlphaThreshold,
  }) async {
    final decoded = img.decodePng(rawPngBytes);
    if (decoded == null) {
      throw ArgumentError('Failed to decode PNG bytes');
    }

    final bounds = _detectBounds(decoded, alphaThreshold);
    if (bounds == null) {
      throw StateError('Signature is empty: no visible pixels found');
    }

    final cropped = _cropWithPadding(decoded, bounds, padding);
    final resized = _resizeProportional(cropped, targetSize);
    final centered = _centerInCanvas(resized, targetSize);

    final pngBytes = img.encodePng(centered);
    return Uint8List.fromList(pngBytes);
  }

  _BoundingBox? _detectBounds(img.Image image, int alphaThreshold) {
    int minX = image.width;
    int minY = image.height;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > alphaThreshold) {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }

    if (maxX < 0) return null;
    return _BoundingBox(minX, minY, maxX, maxY);
  }

  img.Image _cropWithPadding(
    img.Image image,
    _BoundingBox bounds,
    int padding,
  ) {
    final x = max(0, bounds.minX - padding);
    final y = max(0, bounds.minY - padding);
    final right = min(image.width, bounds.maxX + 1 + padding);
    final bottom = min(image.height, bounds.maxY + 1 + padding);

    return img.copyCrop(
      image,
      x: x,
      y: y,
      width: right - x,
      height: bottom - y,
    );
  }

  img.Image _resizeProportional(img.Image image, int targetSize) {
    if (image.width <= targetSize && image.height <= targetSize) {
      return image;
    }

    final scale = targetSize / max(image.width, image.height);
    final newWidth = (image.width * scale).round();
    final newHeight = (image.height * scale).round();

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  img.Image _centerInCanvas(img.Image image, int canvasSize) {
    final canvas = img.Image(
      width: canvasSize,
      height: canvasSize,
      numChannels: 4,
    );

    final offsetX = (canvasSize - image.width) ~/ 2;
    final offsetY = (canvasSize - image.height) ~/ 2;

    img.compositeImage(canvas, image, dstX: offsetX, dstY: offsetY);
    return canvas;
  }
}

class _BoundingBox {
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;

  const _BoundingBox(this.minX, this.minY, this.maxX, this.maxY);
}
