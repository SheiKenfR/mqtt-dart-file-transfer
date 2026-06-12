import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:poc_sign/features/signature/domain/signature_export_result.dart';

void main() {
  test('constructs with correct values', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    final result = SignatureExportResult(
      bytes: bytes,
      width: 256,
      height: 256,
      mimeType: 'image/png',
      sizeInBytes: 3,
    );

    expect(result.bytes, bytes);
    expect(result.width, 256);
    expect(result.height, 256);
    expect(result.mimeType, 'image/png');
    expect(result.sizeInBytes, 3);
  });

  test('sizeInBytes matches actual byte length', () {
    final bytes = Uint8List(1024);

    final result = SignatureExportResult(
      bytes: bytes,
      width: 256,
      height: 256,
      mimeType: 'image/png',
      sizeInBytes: bytes.length,
    );

    expect(result.sizeInBytes, bytes.length);
  });
}
