import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'image_transfer_result.dart';
import 'mqtt_service.dart';
import 'mqtt_topics.dart';

class MqttImageTransferService {
  MqttImageTransferService(this._mqttService);

  final MqttService _mqttService;

  static const int maxSingleImageSize = 128 * 1024;
  static const Duration ackTimeout = Duration(seconds: 10);

  static const List<int> _pngMagic = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  ];

  Future<ImageTransferResult> sendPng({
    required String targetDeviceId,
    required Uint8List pngBytes,
    String fileName = 'signature.png',
  }) async {
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

    final ackTopic = MqttTopics.imageAck(targetDeviceId, imageId);
    final errorTopic = MqttTopics.imageError(targetDeviceId, imageId);

    _mqttService.subscribe(ackTopic);
    _mqttService.subscribe(errorTopic);

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
    );

    _mqttService.publishBytes(
      MqttTopics.imageData(targetDeviceId, imageId),
      pngBytes,
      qos: MqttQos.atLeastOnce,
    );

    try {
      final response = await _mqttService.messages
          .where((msg) => msg.topic == ackTopic || msg.topic == errorTopic)
          .first
          .timeout(ackTimeout);

      final payload = _extractJsonPayload(response);
      final status = payload['status'] as String?;

      if (status == 'completed') {
        return ImageTransferResult(
          imageId: imageId,
          status: ImageTransferStatus.completed,
        );
      }

      return ImageTransferResult(
        imageId: imageId,
        status: ImageTransferStatus.error,
        reason: payload['reason'] as String?,
      );
    } on TimeoutException {
      return ImageTransferResult(
        imageId: imageId,
        status: ImageTransferStatus.timeout,
      );
    } finally {
      _mqttService.unsubscribe(ackTopic);
      _mqttService.unsubscribe(errorTopic);
    }
  }

  Map<String, dynamic> _extractJsonPayload(
    MqttReceivedMessage<MqttMessage> message,
  ) {
    final publish = message.payload as MqttPublishMessage;
    final bytes = publish.payload.message;
    final jsonStr = utf8.decode(bytes);
    return jsonDecode(jsonStr) as Map<String, dynamic>;
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
