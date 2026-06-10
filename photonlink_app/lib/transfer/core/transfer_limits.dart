/// Resource and protocol limits for optical transfer.
abstract final class TransferLimits {
  /// Maximum file size accepted for QR transfer (~512 KB).
  static const int maxQrFileBytes = 512 * 1024;

  /// Maximum file size accepted for Color Matrix transfer (~2 MB).
  static const int maxColorMatrixFileBytes = 2 * 1024 * 1024;

  /// Legacy alias for QR max file size.
  static const int maxFileBytes = maxQrFileBytes;

  /// Maximum number of chunks per session.
  static const int maxTotalChunks = 4096;

  /// Maximum decoded metadata field lengths.
  static const int maxFileNameLength = 255;

  /// Minimum chunk payload size when auto-shrinking for QR capacity.
  static const int minChunkSize = 64;

  /// Conservative max characters per QR frame (reliable on mid-range cameras).
  static const int maxQrFrameChars = 1800;

  /// Validates file size before read/chunking.
  static void validateFileSize(
    int sizeBytes, {
    int maxBytes = maxQrFileBytes,
    String transportLabel = 'QR',
  }) {
    if (sizeBytes < 0) {
      throw TransferLimitException('Invalid file size');
    }
    if (sizeBytes > maxBytes) {
      throw TransferLimitException(
        'File exceeds ${maxBytes ~/ 1024} KB limit for $transportLabel transfer',
      );
    }
  }

  /// Color Matrix file size validation (up to 2 MB).
  static void validateColorMatrixFileSize(int sizeBytes) {
    validateFileSize(
      sizeBytes,
      maxBytes: maxColorMatrixFileBytes,
      transportLabel: 'Color Matrix',
    );
  }

  /// Validates metadata from a decoded packet.
  static void validateMetadata({
    required String fileName,
    required int fileSize,
    required int totalChunks,
    required String sha256,
    int maxBytes = maxQrFileBytes,
  }) {
    if (fileName.isEmpty || fileName.length > maxFileNameLength) {
      throw TransferLimitException('Invalid file name in metadata');
    }
    if (fileSize < 0 || fileSize > maxBytes) {
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
