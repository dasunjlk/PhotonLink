/// Configuration for retry behavior.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelayMs = 500,
  });

  final int maxAttempts;
  final int baseDelayMs;
}
