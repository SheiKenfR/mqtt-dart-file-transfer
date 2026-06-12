import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_service.dart';
import 'mqtt_topics.dart';

class MqttImageTransferService {
  MqttImageTransferService(this._mqttService);

  final MqttService _mqttService;

  static const int maxSingleImageSize = 128 * 1024;

  static const List<int> _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  String sendPng({
    required String targetDeviceId,
    required Uint8List pngBytes,
    String fileName = 'signature.png',
  }) {
    if (!_mqttService.isConnected) {
      throw StateError('MQTT is not connected.');
    }

    if (!_isPng(pngBytes)) {
      throw ArgumentError('File is not a valid PNG.');
    }

    if (pngBytes.length > maxSingleImageSize) {
      throw ArgumentError(
        'PNG too large for single-message transfer '
        '(${pngBytes.length} bytes, max $maxSingleImageSize).',
      );
    }

    final imageId = _generateImageId();
    final hash = sha256.convert(pngBytes).toString();

    _mqttService.publishJson(
      MqttTopics.imageMeta(targetDeviceId, imageId),
      {
        'imageId': imageId,
        'fileName': fileName,
        'mimeType': 'image/png',
        'size': pngBytes.length,
        'sha256': hash,
        'encoding': 'binary',
        'transferMode': 'single',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
      qos: MqttQos.atLeastOnce,
      retain: false,
    );

    _mqttService.publishBytes(
      MqttTopics.imageData(targetDeviceId, imageId),
      pngBytes,
      qos: MqttQos.atLeastOnce,
      retain: false,
    );

    return imageId;
  }

  bool _isPng(Uint8List bytes) {
    if (bytes.length < _pngMagic.length) return false;
    for (var i = 0; i < _pngMagic.length; i++) {
      if (bytes[i] != _pngMagic[i]) return false;
    }
    return true;
  }

  String _generateImageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(0xFFFFFF).toRadixString(16);
    return '$timestamp-$random';
  }
}
