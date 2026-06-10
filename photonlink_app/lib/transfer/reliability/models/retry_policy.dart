/// Configurable retry policy for packet retransmission.
class RetryPolicy {
  const RetryPolicy({
    this.maxRetries = 5,
    this.retryTimeoutMs = 30000,
  });

  final int maxRetries;
  final int retryTimeoutMs;

  static const defaultPolicy = RetryPolicy();
}
