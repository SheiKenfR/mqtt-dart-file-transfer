class MqttTopics {
  const MqttTopics._();

  static const String _root = 'educacode/v1';

  static String clientStatus(String clientId) =>
      '$_root/clients/$clientId/status';

  static String imageMeta(String deviceId, String imageId) =>
      '$_root/devices/$deviceId/images/$imageId/meta';

  static String imageData(String deviceId, String imageId) =>
      '$_root/devices/$deviceId/images/$imageId/data';

  static String imageAck(String deviceId, String imageId) =>
      '$_root/devices/$deviceId/images/$imageId/ack';

  static String imageError(String deviceId, String imageId) =>
      '$_root/devices/$deviceId/images/$imageId/error';
}
