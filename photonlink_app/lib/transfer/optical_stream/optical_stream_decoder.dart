import 'optical_stream_frame.dart';

/// Continuous capture decoder with sync maintenance and duplicate detection.
class OpticalStreamDecoder {
  OpticalStreamDecoder({
    this.maxRollingBuffer = 64,
    this.syncAggressiveness = 0.6,
    this.recoverySensitivity = 0.5,
  });

  final int maxRollingBuffer;
  final double syncAggressiveness;
  final double recoverySensitivity;

  bool _syncLocked = false;
  int _lastFrameId = -1;
  int _lastPacketId = -1;
  int _duplicatesIgnored = 0;
  int _droppedFrames = 0;
  int _resyncCount = 0;
  final Set<String> _seenKeys = {};
  final List<OpticalStreamFrame> _rollingBuffer = [];

  bool get syncLocked => _syncLocked;
  int get duplicatesIgnored => _duplicatesIgnored;
  int get droppedFrames => _droppedFrames;
  int get resyncCount => _resyncCount;
  List<OpticalStreamFrame> get rollingBuffer => List.unmodifiable(_rollingBuffer);

  /// Processes a raw detected frame; returns null for duplicates or invalid.
  OpticalStreamFrame? ingestDetectedFrame(
    OpticalStreamFrame raw, {
    required bool detected,
    double detectionAccuracy = 0,
  }) {
    if (!detected || raw.cells.isEmpty) {
      _droppedFrames++;
      if (_syncLocked && detectionAccuracy < syncAggressiveness * 0.5) {
        _syncLocked = false;
        _resyncCount++;
      }
      return null;
    }

    if (!_syncLocked) {
      if (raw.packetType.isMetadata && detectionAccuracy >= syncAggressiveness) {
        _syncLocked = true;
      } else if (detectionAccuracy < syncAggressiveness) {
        _droppedFrames++;
        return null;
      } else {
        _syncLocked = true;
      }
    } else if (detectionAccuracy < syncAggressiveness * recoverySensitivity) {
      _syncLocked = false;
      _resyncCount++;
      _droppedFrames++;
      return null;
    }

    final key = '${raw.frameId}:${raw.packetId}';
    if (_seenKeys.contains(key)) {
      _duplicatesIgnored++;
      return null;
    }
    _seenKeys.add(key);
    _lastFrameId = raw.frameId;
    _lastPacketId = raw.packetId;

    _rollingBuffer.add(raw);
    while (_rollingBuffer.length > maxRollingBuffer) {
      _rollingBuffer.removeAt(0);
    }

    return raw;
  }

  void reset() {
    _syncLocked = false;
    _lastFrameId = -1;
    _lastPacketId = -1;
    _duplicatesIgnored = 0;
    _droppedFrames = 0;
    _resyncCount = 0;
    _seenKeys.clear();
    _rollingBuffer.clear();
  }
}
