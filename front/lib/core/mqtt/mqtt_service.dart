import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

import 'mqtt_config.dart';
import 'mqtt_topics.dart';

class MqttService {
  MqttService(this._config);

  final MqttConfig _config;
  late final MqttServerClient _client;

  final _messagesController =
      StreamController<MqttReceivedMessage<MqttMessage>>.broadcast();

  Stream<MqttReceivedMessage<MqttMessage>> get messages =>
      _messagesController.stream;

  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    _client = MqttServerClient.withPort(
      _config.host,
      _config.clientId,
      _config.port,
    );

    _client.keepAlivePeriod = _config.keepAliveSeconds;
    _client.logging(on: false);
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;

    if (_config.useMqtt311) {
      _client.setProtocolV311();
    } else {
      _client.setProtocolV31();
    }

    final connectMessage = MqttConnectMessage()
        .withClientIdentifier(_config.clientId)
        .startClean()
        .withWillTopic(MqttTopics.clientStatus(_config.clientId))
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce);

    _client.connectionMessage = connectMessage;

    try {
      await _client.connect(_config.username, _config.password);
    } catch (_) {
      _client.disconnect();
      rethrow;
    }

    if (!isConnected) {
      final status = _client.connectionStatus;
      _client.disconnect();
      throw StateError('MQTT connection failed: $status');
    }

    _client.updates?.listen((events) {
      for (final event in events) {
        _messagesController.add(event);
      }
    });
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (!isConnected) {
      throw StateError('Cannot subscribe: MQTT client is not connected.');
    }
    _client.subscribe(topic, qos);
  }

  int publishJson(
    String topic,
    Map<String, dynamic> payload, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    final builder = MqttClientPayloadBuilder();
    builder.addUTF8String(jsonEncode(payload));
    return _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  int publishBytes(
    String topic,
    List<int> bytes, {
    MqttQos qos = MqttQos.atLeastOnce,
    bool retain = false,
  }) {
    final buffer = Uint8Buffer()..addAll(bytes);
    final builder = MqttClientPayloadBuilder();
    builder.addBuffer(buffer);
    return _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void disconnect() {
    _client.disconnect();
  }

  Future<void> dispose() async {
    disconnect();
    await _messagesController.close();
  }
}
