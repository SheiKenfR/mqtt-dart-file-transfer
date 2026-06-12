import 'dart:typed_data';

class SignatureExportResult {
  final Uint8List bytes;
  final int width;
  final int height;
  final String mimeType;
  final int sizeInBytes;

  const SignatureExportResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.sizeInBytes,
  });
}
