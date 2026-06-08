import '../../protocols/interfaces/reliability/acknowledgement_manager.dart';
import '../../protocols/interfaces/transfer_packet.dart';

/// In-memory acknowledgement tracking.
class AcknowledgementManagerImpl implements AcknowledgementManager {
  String _sessionId = '';
  int _totalPackets = 0;
  final Set<int> _acked = {};

  @override
  void reset({required String sessionId, required int totalPackets}) {
    _sessionId = sessionId;
    _totalPackets = totalPackets;
    _acked.clear();
  }

  @override
  void recordAcknowledged(int packetId) {
    if (packetId >= 0 && packetId < _totalPackets) {
      _acked.add(packetId);
    }
  }

  @override
  void processAck(AckPacket ack) {
    if (ack.sessionId != _sessionId) return;
    for (final id in ack.packetIds) {
      recordAcknowledged(id);
    }
  }

  @override
  Set<int> get acknowledgedIds => Set.unmodifiable(_acked);

  @override
  bool isAcknowledged(int packetId) => _acked.contains(packetId);

  @override
  bool get allAcknowledged =>
      _totalPackets > 0 && _acked.length == _totalPackets;

  @override
  AckPacket buildAck({required String sessionId, List<int>? packetIds}) {
    return AckPacket(
      sessionId: sessionId,
      packetIds: packetIds ?? _acked.toList()..sort(),
      timestamp: DateTime.now(),
    );
  }
}
