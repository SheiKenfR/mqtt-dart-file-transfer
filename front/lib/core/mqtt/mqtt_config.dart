class MqttConfig {
  const MqttConfig({
    required this.host,
    required this.port,
    required this.clientId,
    this.username,
    this.password,
    this.useMqtt311 = true,
    this.keepAliveSeconds = 30,
  });

  final String host;
  final int port;
  final String clientId;
  final String? username;
  final String? password;
  final bool useMqtt311;
  final int keepAliveSeconds;
}
