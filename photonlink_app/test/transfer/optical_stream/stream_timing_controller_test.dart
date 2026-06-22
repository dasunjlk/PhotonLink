import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/optical_stream/stream_timing_controller.dart';

void main() {
  test('timing controller tracks emit and decode rates', () {
    final timing = StreamTimingController(framesPerSecond: 8.0);
    timing.onEmit(1000);
    timing.onEmit(1125);
    expect(timing.framesEmitted, 2);
    expect(timing.jitterMs, greaterThanOrEqualTo(0));

    timing.onDecode(1200, sinceLastDecodeMs: 125);
    expect(timing.framesDecoded, 1);
    expect(timing.measuredDecodeFps, greaterThan(0));
  });

  test('dropped frame slows pacing', () {
    final timing = StreamTimingController(framesPerSecond: 10.0);
    final before = timing.targetIntervalMs;
    timing.onDroppedFrame();
    expect(timing.targetIntervalMs, greaterThan(before));
  });
}
