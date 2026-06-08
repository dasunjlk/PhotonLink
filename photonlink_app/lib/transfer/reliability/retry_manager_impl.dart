import '../../protocols/interfaces/reliability/retry_manager.dart';
import 'models/retry_policy.dart';

/// Per-packet retry tracking with permanent failure detection.
class RetryManagerImpl implements RetryManager {
  RetryManagerImpl({RetryPolicy policy = RetryPolicy.defaultPolicy})
      : _policy = policy;

  final RetryPolicy _policy;
  int _totalPackets = 0;
  final Map<int, int> _retryCounts = {};
  final Set<int> _permanentFailures = {};
  int _totalRetries = 0;

  @override
  void reset({required int totalPackets}) {
    _totalPackets = totalPackets;
    _retryCounts.clear();
    _permanentFailures.clear();
    _totalRetries = 0;
  }

  @override
  bool canRetry(int packetId) {
    if (packetId < 0 || packetId >= _totalPackets) return false;
    if (_permanentFailures.contains(packetId)) return false;
    return (_retryCounts[packetId] ?? 0) < _policy.maxRetries;
  }

  @override
  void recordRetry(int packetId) {
    final count = (_retryCounts[packetId] ?? 0) + 1;
    _retryCounts[packetId] = count;
    _totalRetries++;
    if (count >= _policy.maxRetries) {
      _permanentFailures.add(packetId);
    }
  }

  @override
  int retryCountFor(int packetId) => _retryCounts[packetId] ?? 0;

  @override
  Set<int> get permanentlyFailedIds => Set.unmodifiable(_permanentFailures);

  @override
  int get totalRetries => _totalRetries;

  @override
  bool get hasPermanentFailures => _permanentFailures.isNotEmpty;
}
