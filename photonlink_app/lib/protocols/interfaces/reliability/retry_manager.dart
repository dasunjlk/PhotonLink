import 'retry_policy.dart';

/// Manages retry attempts for recoverable transfer steps.
abstract interface class RetryManager {
  RetryPolicy get policy;
  bool shouldRetry(String operationKey);
  void recordAttempt(String operationKey);
  void reset(String operationKey);
  int attemptsFor(String operationKey);
}
