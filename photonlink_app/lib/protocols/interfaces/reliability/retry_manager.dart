/// Manages per-packet retry counts and failure classification.
abstract interface class RetryManager {
  void reset({required int totalPackets});

  bool canRetry(int packetId);

  void recordRetry(int packetId);

  int retryCountFor(int packetId);

  Set<int> get permanentlyFailedIds;

  int get totalRetries;

  bool get hasPermanentFailures;
}
