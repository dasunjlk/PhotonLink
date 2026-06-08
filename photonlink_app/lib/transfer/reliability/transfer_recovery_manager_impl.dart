import '../../protocols/interfaces/reliability/missing_packet_tracker.dart';
import '../../protocols/interfaces/reliability/transfer_recovery_manager.dart';
import 'missing_packet_tracker_impl.dart';

/// Computes missing sets and restores trackers from persisted state.
class TransferRecoveryManagerImpl implements TransferRecoveryManager {
  @override
  Set<int> computeMissingIds({
    required int totalPackets,
    required Set<int> receivedIds,
  }) {
    final missing = <int>{};
    for (var i = 0; i < totalPackets; i++) {
      if (!receivedIds.contains(i)) missing.add(i);
    }
    return missing;
  }

  @override
  MissingPacketTracker restoreTracker({
    required String sessionId,
    required int totalPackets,
    required Set<int> receivedIds,
  }) {
    final tracker = MissingPacketTrackerImpl();
    tracker.reset(sessionId: sessionId, totalPackets: totalPackets);
    for (final id in receivedIds) {
      tracker.recordReceived(id);
    }
    return tracker;
  }
}
