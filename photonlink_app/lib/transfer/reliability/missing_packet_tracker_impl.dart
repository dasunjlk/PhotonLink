import '../../protocols/interfaces/reliability/missing_packet_tracker.dart';

/// Tracks received, missing, and duplicate packets.
class MissingPacketTrackerImpl implements MissingPacketTracker {
  final Set<int> _received = {};
  int _duplicates = 0;
  int _totalExpected = 0;

  @override
  int get duplicatesIgnored => _duplicates;

  @override
  Set<int> get receivedPacketIds => Set.unmodifiable(_received);

  @override
  int get totalExpected => _totalExpected;

  @override
  Set<int> get missingPacketIds {
    if (_totalExpected <= 0) return {};
    return {for (var i = 0; i < _totalExpected; i++) i}
        .difference(_received);
  }

  @override
  void onPacketReceived(int packetId, {required bool isNew}) {
    if (isNew) {
      _received.add(packetId);
    } else {
      _duplicates++;
    }
  }

  @override
  void reset() {
    _received.clear();
    _duplicates = 0;
    _totalExpected = 0;
  }

  @override
  void setTotalExpected(int total) {
    _totalExpected = total;
  }
}
