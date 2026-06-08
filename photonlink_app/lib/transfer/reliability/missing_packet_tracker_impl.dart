import '../../protocols/interfaces/reliability/missing_packet_tracker.dart';

/// Efficient packet ID tracking with Set-based O(1) ops.
class MissingPacketTrackerImpl implements MissingPacketTracker {
  String _sessionId = '';
  int _totalPackets = 0;
  final Set<int> _received = {};
  int _duplicateCount = 0;

  @override
  void reset({required String sessionId, required int totalPackets}) {
    _sessionId = sessionId;
    _totalPackets = totalPackets;
    _received.clear();
    _duplicateCount = 0;
  }

  @override
  bool recordReceived(int packetId) {
    if (_sessionId.isEmpty) return false;
    if (packetId < 0 || packetId >= _totalPackets) return false;
    if (_received.contains(packetId)) {
      _duplicateCount++;
      return false;
    }
    _received.add(packetId);
    return true;
  }

  @override
  Set<int> get receivedIds => Set.unmodifiable(_received);

  @override
  Set<int> get missingIds {
    if (_totalPackets == 0) return {};
    final missing = <int>{};
    for (var i = 0; i < _totalPackets; i++) {
      if (!_received.contains(i)) missing.add(i);
    }
    return missing;
  }

  @override
  List<PacketIdRange> get missingRanges {
    final missing = missingIds.toList()..sort();
    if (missing.isEmpty) return [];
    final ranges = <PacketIdRange>[];
    var start = missing.first;
    var end = start;
    for (var i = 1; i < missing.length; i++) {
      if (missing[i] == end + 1) {
        end = missing[i];
      } else {
        ranges.add(PacketIdRange(start, end));
        start = missing[i];
        end = start;
      }
    }
    ranges.add(PacketIdRange(start, end));
    return ranges;
  }

  @override
  int get duplicateCount => _duplicateCount;

  @override
  int get acceptedCount => _received.length;

  @override
  bool get isComplete =>
      _totalPackets > 0 && _received.length == _totalPackets;

  @override
  double get progress {
    if (_totalPackets == 0) return 0;
    return _received.length / _totalPackets;
  }
}
