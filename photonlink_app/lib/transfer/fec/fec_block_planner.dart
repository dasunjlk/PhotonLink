import 'dart:typed_data';

import '../../protocols/interfaces/transfer_packet.dart';
import 'models/fec_configuration.dart';

/// Describes a single FEC block within a transfer.
class FecBlockPlan {
  const FecBlockPlan({
    required this.blockIndex,
    required this.dataChunkIds,
    required this.dataCount,
    required this.parityCount,
    required this.symbolLength,
    required this.firstParityId,
  });

  final int blockIndex;
  final List<int> dataChunkIds;
  final int dataCount;
  final int parityCount;
  final int symbolLength;
  final int firstParityId;
}

/// Groups data packets into FEC blocks and computes symbol lengths.
class FecBlockPlanner {
  const FecBlockPlanner();

  /// Plans blocks from [totalChunks] and [config].
  List<FecBlockPlan> planFromTotal({
    required int totalChunks,
    required FecConfiguration config,
    int symbolLength = 0,
  }) {
    if (totalChunks < 1 || !config.enabled) return [];

    final plans = <FecBlockPlan>[];
    var blockIndex = 0;
    var parityId = 0;

    for (var offset = 0; offset < totalChunks; offset += config.blockSize) {
      final end = (offset + config.blockSize <= totalChunks)
          ? offset + config.blockSize
          : totalChunks;
      final chunkIds = List.generate(end - offset, (i) => offset + i);
      final k = chunkIds.length;
      final m = config.parityCountForBlock(k);
      if (m < 1) continue;

      plans.add(
        FecBlockPlan(
          blockIndex: blockIndex,
          dataChunkIds: chunkIds,
          dataCount: k,
          parityCount: m,
          symbolLength: symbolLength,
          firstParityId: parityId,
        ),
      );

      parityId += m;
      blockIndex++;
    }

    return plans;
  }

  List<FecBlockPlan> plan({
    required List<DataPacket> dataPackets,
    required FecConfiguration config,
  }) {
    if (dataPackets.isEmpty || !config.enabled) return [];

    final totalChunks = dataPackets.first.totalChunks;
    final symbolLength = dataPackets
        .map((p) => p.payload.length)
        .reduce((a, b) => a > b ? a : b);

    final plans = planFromTotal(
      totalChunks: totalChunks,
      config: config,
      symbolLength: symbolLength,
    );

    // Fill symbol lengths from available packets where possible.
    return plans;
  }

  /// Updates symbol length from received data packets.
  List<FecBlockPlan> planForRecovery({
    required int totalChunks,
    required FecConfiguration config,
    required Map<int, DataPacket> receivedData,
  }) {
    final basePlans = planFromTotal(
      totalChunks: totalChunks,
      config: config,
    );
    if (basePlans.isEmpty) return [];

    return basePlans.map((plan) {
      var maxLen = plan.symbolLength;
      for (final id in plan.dataChunkIds) {
        final packet = receivedData[id];
        if (packet != null && packet.payload.length > maxLen) {
          maxLen = packet.payload.length;
        }
      }
      // Infer symbol length from parity if no data received.
      if (maxLen == 0) maxLen = 1;
      return FecBlockPlan(
        blockIndex: plan.blockIndex,
        dataChunkIds: plan.dataChunkIds,
        dataCount: plan.dataCount,
        parityCount: plan.parityCount,
        symbolLength: maxLen,
        firstParityId: plan.firstParityId,
      );
    }).toList();
  }

  /// Pads packet payload to [symbolLength] with zero bytes.
  static Uint8List padPayload(Uint8List payload, int symbolLength) {
    if (payload.length == symbolLength) return payload;
    if (payload.length > symbolLength) {
      return Uint8List.sublistView(payload, 0, symbolLength);
    }
    final padded = Uint8List(symbolLength);
    padded.setRange(0, payload.length, payload);
    return padded;
  }

  /// Trims padded payload back to original length.
  static Uint8List trimPayload(Uint8List padded, int originalLength) {
    if (padded.length == originalLength) return padded;
    return Uint8List.sublistView(padded, 0, originalLength);
  }
}
