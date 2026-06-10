import 'dart:async';

import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';

/// Drives cyclic frame emission for any optical transport.
class FrameStreamController<TFrame> {
  FrameStreamController({
    required TransferEncoder<TFrame> encoder,
  }) : _encoder = encoder;

  final TransferEncoder<TFrame> _encoder;
  Timer? _timer;
  List<TransferPacket> _packets = [];
  int _frameIndex = 0;
  int _loopCount = 0;
  double _framesPerSecond = 2.0;
  int _framesGenerated = 0;
  void Function(TFrame frameData, int index, int total)? _onFrame;

  TFrame? get currentFrame {
    if (_packets.isEmpty) return null;
    return _encoder.encodeFrame(_packets[_frameIndex]);
  }

  int get frameIndex => _frameIndex;
  int get totalFrames => _packets.length;
  int get loopCount => _loopCount;
  int get framesGenerated => _framesGenerated;

  double get loopProgress {
    if (_packets.isEmpty) return 0;
    return (_frameIndex + 1) / _packets.length;
  }

  bool get isRunning => _timer?.isActive ?? false;
  double get framesPerSecond => _framesPerSecond;

  void setPackets(List<TransferPacket> packets) {
    stop();
    _packets = List.from(packets);
    _frameIndex = 0;
    _loopCount = 0;
  }

  void start({
    required void Function(TFrame frameData, int index, int total) onFrame,
    double framesPerSecond = 2.0,
  }) {
    stop();
    if (_packets.isEmpty) return;

    _framesPerSecond = framesPerSecond;
    _onFrame = onFrame;
    _emitCurrentFrame();
    _scheduleTimer();
  }

  void setFrameRate(double framesPerSecond) {
    if (framesPerSecond == _framesPerSecond) return;
    _framesPerSecond = framesPerSecond;
    if (_timer?.isActive ?? false) {
      _timer?.cancel();
      _scheduleTimer();
    }
  }

  void _scheduleTimer() {
    if (_packets.isEmpty || _onFrame == null) return;
    final interval = Duration(
      milliseconds: (1000 / _framesPerSecond).round().clamp(50, 10000),
    );
    _timer = Timer.periodic(interval, (_) {
      _frameIndex++;
      if (_frameIndex >= _packets.length) {
        _frameIndex = 0;
        _loopCount++;
      }
      _emitCurrentFrame();
    });
  }

  void _emitCurrentFrame() {
    final callback = _onFrame;
    if (callback == null || _packets.isEmpty) return;
    final frame = _encoder.encodeFrame(_packets[_frameIndex]);
    _framesGenerated++;
    callback(frame, _frameIndex, _packets.length);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
