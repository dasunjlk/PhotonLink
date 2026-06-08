import 'dart:async';

import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import 'qr_frame_codec.dart';

/// Drives cyclic QR frame emission for the sender.
class QrStreamController {
  QrStreamController({
    TransferEncoder<String>? encoder,
  }) : _encoder = encoder ?? const QrFrameCodec();

  final TransferEncoder<String> _encoder;
  Timer? _timer;
  List<TransferPacket> _packets = [];
  int _frameIndex = 0;
  int _loopCount = 0;

  String? get currentFrameData {
    if (_packets.isEmpty) return null;
    return _encoder.encodeFrame(_packets[_frameIndex]);
  }

  int get frameIndex => _frameIndex;
  int get totalFrames => _packets.length;
  int get loopCount => _loopCount;

  /// Fraction of current loop progress (0..1 within one full cycle).
  double get loopProgress {
    if (_packets.isEmpty) return 0;
    return (_frameIndex + 1) / _packets.length;
  }

  bool get isRunning => _timer?.isActive ?? false;

  void setPackets(List<TransferPacket> packets) {
    stop();
    _packets = List.from(packets);
    _frameIndex = 0;
    _loopCount = 0;
  }

  /// Starts cycling frames at [framesPerSecond].
  void start({
    required void Function(String frameData, int index, int total) onFrame,
    double framesPerSecond = 2.0,
  }) {
    stop();
    if (_packets.isEmpty) return;

    final interval = Duration(
      milliseconds: (1000 / framesPerSecond).round().clamp(100, 10000),
    );

    onFrame(
      _encoder.encodeFrame(_packets[_frameIndex]),
      _frameIndex,
      _packets.length,
    );

    _timer = Timer.periodic(interval, (_) {
      _frameIndex++;
      if (_frameIndex >= _packets.length) {
        _frameIndex = 0;
        _loopCount++;
      }
      onFrame(
        _encoder.encodeFrame(_packets[_frameIndex]),
        _frameIndex,
        _packets.length,
      );
    });
  }

  void setFrameRate(double framesPerSecond) {
    // Caller should restart with new rate; store for convenience
    _framesPerSecond = framesPerSecond;
  }

  double _framesPerSecond = 2.0;
  double get framesPerSecond => _framesPerSecond;

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
