import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/reliability/acknowledgement_manager_impl.dart';
import 'package:photonlink_app/transfer/reliability/missing_packet_tracker_impl.dart';
import 'package:photonlink_app/transfer/reliability/retry_manager_impl.dart';

void main() {
  test('missing packet tracker tracks duplicates', () {
    final tracker = MissingPacketTrackerImpl();
    tracker.setTotalExpected(3);
    tracker.onPacketReceived(0, isNew: true);
    tracker.onPacketReceived(0, isNew: false);
    tracker.onPacketReceived(1, isNew: true);

    expect(tracker.receivedPacketIds, {0, 1});
    expect(tracker.duplicatesIgnored, 1);
    expect(tracker.missingPacketIds, {2});
  });

  test('retry manager respects max attempts', () {
    final retry = RetryManagerImpl();
    expect(retry.shouldRetry('op'), isTrue);
    retry.recordAttempt('op');
    retry.recordAttempt('op');
    retry.recordAttempt('op');
    expect(retry.shouldRetry('op'), isFalse);
  });

  test('ack manager records ack and nak', () {
    final ack = AcknowledgementManagerImpl();
    ack.recordAck(1);
    ack.recordNak(2);
    expect(ack.acknowledgedPacketIds, {1});
    expect(ack.negativeAckPacketIds, {2});
  });
}
