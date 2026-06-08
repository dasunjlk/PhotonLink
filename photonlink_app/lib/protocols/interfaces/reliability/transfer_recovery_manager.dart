import 'missing_packet_tracker.dart';

/// Restores transfer state and computes missing packets for resume.
abstract interface class TransferRecoveryManager {
  /// Missing IDs = all expected − already received.
  Set<int> computeMissingIds({
    required int totalPackets,
    required Set<int> receivedIds,
  });

  MissingPacketTracker restoreTracker({
    required String sessionId,
    required int totalPackets,
    required Set<int> receivedIds,
  });
}
