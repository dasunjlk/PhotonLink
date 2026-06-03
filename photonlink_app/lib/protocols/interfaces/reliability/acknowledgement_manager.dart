import '../transfer_packet.dart';

/// Tracks and processes packet acknowledgements (transport-agnostic).
abstract interface class AcknowledgementManager {
  void reset({required String sessionId, required int totalPackets});

  void recordAcknowledged(int packetId);

  void processAck(AckPacket ack);

  Set<int> get acknowledgedIds;

  bool isAcknowledged(int packetId);

  bool get allAcknowledged;

  AckPacket buildAck({required String sessionId, List<int>? packetIds});
}
