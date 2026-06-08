import '../../protocols/interfaces/reliability/retry_manager.dart';
import '../../protocols/interfaces/reliability/retry_policy.dart';

/// In-memory retry counter per operation key.
class RetryManagerImpl implements RetryManager {
  RetryManagerImpl({RetryPolicy? policy})
      : _policy = policy ?? const RetryPolicy();

  final RetryPolicy _policy;
  final Map<String, int> _attempts = {};

  @override
  RetryPolicy get policy => _policy;

  @override
  int attemptsFor(String operationKey) => _attempts[operationKey] ?? 0;

  @override
  void recordAttempt(String operationKey) {
    _attempts[operationKey] = attemptsFor(operationKey) + 1;
  }

  @override
  void reset(String operationKey) {
    _attempts.remove(operationKey);
  }

  @override
  bool shouldRetry(String operationKey) {
    return attemptsFor(operationKey) < _policy.maxAttempts;
  }
}
