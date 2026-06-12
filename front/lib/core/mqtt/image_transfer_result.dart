enum ImageTransferStatus { completed, error, timeout }

class ImageTransferResult {
  const ImageTransferResult({
    required this.imageId,
    required this.status,
    this.reason,
  });

  final String imageId;
  final ImageTransferStatus status;
  final String? reason;

  bool get isSuccess => status == ImageTransferStatus.completed;
}
