import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/reliability/models/retry_policy.dart';
import 'package:photonlink_app/transfer/reliability/retry_manager_impl.dart';

void main() {
  test('retry until permanent failure', () {
    final mgr = RetryManagerImpl(policy: const RetryPolicy(maxRetries: 2));
    mgr.reset(totalPackets: 10);
    expect(mgr.canRetry(1), isTrue);
    mgr.recordRetry(1);
    mgr.recordRetry(1);
    expect(mgr.canRetry(1), isFalse);
    expect(mgr.permanentlyFailedIds, contains(1));
  });
}
