import 'dart:typed_data';

import 'package:signature/signature.dart';

import '../domain/signature_export_result.dart';
import '../infrastructure/signature_image_processor.dart';
import '../infrastructure/signature_storage_service.dart';

class SignatureFeatureController {
  final SignatureImageProcessor _imageProcessor;
  final SignatureStorageService _storageService;

  SignatureFeatureController({
    SignatureImageProcessor? imageProcessor,
    SignatureStorageService? storageService,
  })  : _imageProcessor = imageProcessor ?? SignatureImageProcessor(),
        _storageService = storageService ?? SignatureStorageService();

  Future<SignatureExportResult> exportSignature(
    SignatureController signatureController,
  ) async {
    if (signatureController.isEmpty) {
      throw StateError('Cannot export an empty signature');
    }

    final rawBytes = await signatureController.toPngBytes();
    if (rawBytes == null || rawBytes.isEmpty) {
      throw StateError('Failed to export signature as PNG');
    }

    final processedBytes = await _imageProcessor.processSignature(rawBytes);

    return SignatureExportResult(
      bytes: processedBytes,
      width: 256,
      height: 256,
      mimeType: 'image/png',
      sizeInBytes: processedBytes.length,
    );
  }

  Future<String> exportAndSave(
    SignatureController signatureController,
  ) async {
    final result = await exportSignature(signatureController);
    final file = await _storageService.saveLocally(result);
    return file.path;
  }
}
