import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';

import 'core/mqtt/mqtt_config.dart';
import 'core/mqtt/mqtt_host.g.dart';
import 'core/mqtt/mqtt_image_transfer_service.dart';
import 'core/mqtt/mqtt_service.dart';
import 'features/signature/presentation/signature_page.dart';

late final MqttService mqttService;
late final MqttImageTransferService mqttImageTransferService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final clientSuffix = Random().nextInt(0xFFFF).toRadixString(16);

  final config = MqttConfig(
    host: mqttHostIp,
    port: 1883,
    clientId: 'poc-sign-$clientSuffix',
  );

  mqttService = MqttService(config);

  try {
    await mqttService.connect();
    dev.log('MQTT connected to ${config.host}:${config.port}');
  } catch (e) {
    dev.log('MQTT connection failed: $e');
  }

  mqttImageTransferService = MqttImageTransferService(mqttService);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POC Signature',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: SignaturePage(
        mqttTransferService: mqttImageTransferService,
      ),
    );
  }
}
