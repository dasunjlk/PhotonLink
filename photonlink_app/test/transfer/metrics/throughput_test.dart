import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/metrics/throughput_monitor.dart';

void main() {
  test('throughput averages bytes over time', () {
    final monitor = ThroughputMonitor();
    monitor.start();
    monitor.recordBytes(1000);
    monitor.recordBytes(1000);
    final snap = monitor.snapshot();
    expect(snap.totalBytes, 2000);
    expect(snap.averageBytesPerSec, greaterThanOrEqualTo(0));
  });
}
