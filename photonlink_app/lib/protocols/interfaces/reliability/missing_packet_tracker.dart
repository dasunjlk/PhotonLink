/// Tracks received, missing, and duplicate packet IDs (transport-agnostic).
abstract interface class MissingPacketTracker {
  void reset({required String sessionId, required int totalPackets});

  /// Returns true if newly accepted, false if duplicate or invalid.
  bool recordReceived(int packetId);

  Set<int> get receivedIds;

  Set<int> get missingIds;

  List<PacketIdRange> get missingRanges;

  int get duplicateCount;

  int get acceptedCount;

  bool get isComplete;

  double get progress;
}

/// Inclusive range of missing packet IDs.
class PacketIdRange {
  const PacketIdRange(this.start, this.end);

  final int start;
  final int end;

  @override
  String toString() => start == end ? '$start' : '$start-$end';
}
