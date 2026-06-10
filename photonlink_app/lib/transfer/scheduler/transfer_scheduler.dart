import '../../protocols/interfaces/transfer_packet.dart';
import 'transfer_mode.dart';

/// Schedules packet transmission order and pacing (transport-agnostic).
class TransferScheduler {
  const TransferScheduler();

  /// Orders packets: retransmits first, then control, then fresh data.
  ScheduledRound scheduleRound({
    required List<DataPacket> allDataPackets,
    required Set<int> missingIds,
    required TransferMode mode,
    ControlPacket? endOfRound,
  }) {
    final retransmit = <DataPacket>[];
    for (final p in allDataPackets) {
      if (missingIds.contains(p.chunkId)) {
        retransmit.add(p);
      }
    }
    retransmit.sort((a, b) => a.chunkId.compareTo(b.chunkId));

    final queue = <TransferPacket>[
      ...retransmit,
      if (endOfRound != null) endOfRound,
    ];

    return ScheduledRound(
      packets: queue,
      framesPerSecond: mode.framesPerSecond,
      retransmitCount: retransmit.length,
    );
  }

  /// Full data round including end-of-round control.
  List<TransferPacket> buildDataRoundQueue({
    required List<DataPacket> packetsToSend,
    required String sessionId,
  }) {
    return [
      ...packetsToSend,
      ControlPacket(
        sessionId: sessionId,
        type: ControlType.endOfRound,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

/// Output of a scheduling pass.
class ScheduledRound {
  const ScheduledRound({
    required this.packets,
    required this.framesPerSecond,
    required this.retransmitCount,
  });

  final List<TransferPacket> packets;
  final double framesPerSecond;
  final int retransmitCount;
}
