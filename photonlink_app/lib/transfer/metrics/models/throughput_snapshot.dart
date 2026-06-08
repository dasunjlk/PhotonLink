/// Point-in-time throughput measurements.
class ThroughputSnapshot {
  const ThroughputSnapshot({
    this.currentBytesPerSec = 0,
    this.averageBytesPerSec = 0,
    this.peakBytesPerSec = 0,
    this.packetsPerSec = 0,
    this.durationMs = 0,
    this.compressionRatio = 1,
    this.encryptionOverheadBytes = 0,
    this.totalBytes = 0,
  });

  final double currentBytesPerSec;
  final double averageBytesPerSec;
  final double peakBytesPerSec;
  final double packetsPerSec;
  final int durationMs;
  final double compressionRatio;
  final int encryptionOverheadBytes;
  final int totalBytes;

  Map<String, dynamic> toJson() => {
        'currentBytesPerSec': currentBytesPerSec,
        'averageBytesPerSec': averageBytesPerSec,
        'peakBytesPerSec': peakBytesPerSec,
        'packetsPerSec': packetsPerSec,
        'durationMs': durationMs,
        'compressionRatio': compressionRatio,
        'encryptionOverheadBytes': encryptionOverheadBytes,
        'totalBytes': totalBytes,
      };
}
