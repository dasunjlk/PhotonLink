import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/reliability/missing_packet_tracker_impl.dart';

void main() {
  test('detects missing and duplicate packets', () {
    final t = MissingPacketTrackerImpl();
    t.reset(sessionId: 's', totalPackets: 5);
    expect(t.recordReceived(0), isTrue);
    expect(t.recordReceived(0), isFalse);
    expect(t.duplicateCount, 1);
    expect(t.missingIds, {1, 2, 3, 4});
    expect(t.missingRanges.length, greaterThan(0));
  });

  test('isComplete requires all indices', () {
    final t = MissingPacketTrackerImpl();
    t.reset(sessionId: 's', totalPackets: 3);
    t.recordReceived(0);
    t.recordReceived(2);
    expect(t.isComplete, isFalse);
    t.recordReceived(1);
    expect(t.isComplete, isTrue);
  });
}
