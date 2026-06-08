/// Scaffold for bidirectional ACK/NAK feedback (future transports).
abstract interface class AcknowledgementManager {
  void recordAck(int packetId);
  void recordNak(int packetId);
  Set<int> get acknowledgedPacketIds;
  Set<int> get negativeAckPacketIds;
  void reset();
}
