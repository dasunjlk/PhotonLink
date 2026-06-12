import 'dart:async';

import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/frame_stream_controller.dart';
import 'optical_stream_frame.dart';
import 'stream_timing_controller.dart';

/// Continuous optical stream frame generator with adaptive pacing.
class OpticalStreamEncoder {
  OpticalStreamEncoder({
    required TransferEncoder<OpticalStreamFrame> encoder,
    double framesPerSecond = 8.0,
  })  : _stream = FrameStreamController<OpticalStreamFrame>(encoder: encoder),
        _timing = StreamTimingController(framesPerSecond: framesPerSecond);

  final FrameStreamController<OpticalStreamFrame> _stream;
  final StreamTimingController _timing;

  StreamTimingController get timing => _timing;
  bool get isRunning => _stream.isRunning;
  int get framesGenerated => _stream.framesGenerated;
  int get loopCount => _stream.loopCount;

  void setPackets(List<TransferPacket> packets) {
    _stream.setPackets(packets);
  }

  void start({
    required void Function(
      OpticalStreamFrame frame,
      int index,
      int total,
    ) onFrame,
    double? framesPerSecond,
  }) {
    if (framesPerSecond != null) {
      _timing.setTargetFps(framesPerSecond);
      _stream.setFrameRate(framesPerSecond);
    }

    _stream.start(
      framesPerSecond: _timing.framesPerSecond,
      onFrame: (frame, index, total) {
        _timing.onEmit(DateTime.now().millisecondsSinceEpoch);
        onFrame(frame, index, total);
      },
    );
  }

  void setFrameRate(double fps) {
    _timing.setTargetFps(fps);
    _stream.setFrameRate(fps);
  }

  void stop() => _stream.stop();

  void dispose() {
    _stream.dispose();
    _timing.reset();
  }
}
