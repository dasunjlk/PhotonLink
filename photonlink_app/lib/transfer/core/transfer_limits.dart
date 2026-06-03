/// Resource and protocol limits for QR transfer (Phase 2 MVP).
abstract final class TransferLimits {
  /// Maximum file size accepted for QR transfer (~512 KB).
  static const int maxFileBytes = 512 * 1024;

  /// Maximum number of chunks per session.
  static const int maxTotalChunks = 4096;

  /// Maximum decoded metadata field lengths.
  static const int maxFileNameLength = 255;

  /// Minimum chunk payload size when auto-shrinking for QR capacity.
  static const int minChunkSize = 64;

  /// Conservative max characters per QR frame (reliable on mid-range cameras).
  static const int maxQrFrameChars = 1800;

  /// Validates file size before read/chunking.
  static void validateFileSize(int sizeBytes) {
    if (sizeBytes < 0) {
      throw TransferLimitException('Invalid file size');
    }
    if (sizeBytes > maxFileBytes) {
      throw TransferLimitException(
        'File exceeds ${maxFileBytes ~/ 1024} KB limit for QR transfer',
      );
    }
  }

  /// Validates metadata from a decoded packet.
  static void validateMetadata({
    required String fileName,
    required int fileSize,
    required int totalChunks,
    required String sha256,
  }) {
    if (fileName.isEmpty || fileName.length > maxFileNameLength) {
      throw TransferLimitException('Invalid file name in metadata');
    }
    if (fileSize < 0 || fileSize > maxFileBytes) {
      throw TransferLimitException('Invalid file size in metadata');
    }
    if (totalChunks < 1 || totalChunks > maxTotalChunks) {
      throw TransferLimitException('Invalid chunk count in metadata');
    }
    if (sha256.length != 64 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw TransferLimitException('Invalid SHA-256 in metadata');
    }
  }
}

/// Thrown when transfer limits are exceeded.
class TransferLimitException implements Exception {
  TransferLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}
