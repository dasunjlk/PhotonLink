import '../../protocols/interfaces/reliability/acknowledgement_manager.dart';

/// In-memory ACK/NAK tracker (scaffold for future bidirectional transports).
class AcknowledgementManagerImpl implements AcknowledgementManager {
  final Set<int> _acks = {};
  final Set<int> _naks = {};

  @override
  Set<int> get acknowledgedPacketIds => Set.unmodifiable(_acks);

  @override
  Set<int> get negativeAckPacketIds => Set.unmodifiable(_naks);

  @override
  void recordAck(int packetId) {
    _acks.add(packetId);
    _naks.remove(packetId);
  }

  @override
  void recordNak(int packetId) {
    _naks.add(packetId);
  }

  @override
  void reset() {
    _acks.clear();
    _naks.clear();
  }
}
