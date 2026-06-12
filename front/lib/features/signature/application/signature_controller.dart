import 'dart:developer' as dev;

import 'package:signature/signature.dart';

import '../../../core/mqtt/mqtt_image_transfer_service.dart';
import '../domain/signature_export_result.dart';
import '../infrastructure/signature_image_processor.dart';
import '../infrastructure/signature_storage_service.dart';

class SignatureFeatureController {
  final SignatureImageProcessor _imageProcessor;
  final SignatureStorageService _storageService;
  final MqttImageTransferService? _mqttTransferService;
  final String _targetDeviceId;

  SignatureFeatureController({
    SignatureImageProcessor? imageProcessor,
    SignatureStorageService? storageService,
    MqttImageTransferService? mqttTransferService,
    String targetDeviceId = 'default',
  })  : _imageProcessor = imageProcessor ?? SignatureImageProcessor(),
        _storageService = storageService ?? SignatureStorageService(),
        _mqttTransferService = mqttTransferService,
        _targetDeviceId = targetDeviceId;

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

    _publishToMqtt(result);

    return file.path;
  }

  void _publishToMqtt(SignatureExportResult result) {
    if (_mqttTransferService == null) return;

    try {
      final imageId = _mqttTransferService.sendPng(
        targetDeviceId: _targetDeviceId,
        pngBytes: result.bytes,
      );
      dev.log('Signature published to MQTT: $imageId');
    } catch (e) {
      dev.log('MQTT publish failed: $e');
    }
  }
}
