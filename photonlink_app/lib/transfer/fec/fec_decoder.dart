import 'dart:typed_data';

import '../../protocols/interfaces/transfer_packet.dart';
import 'fec_block_planner.dart';
import 'models/fec_codec_type.dart';
import 'models/fec_configuration.dart';
import 'models/fec_recovery_result.dart';
import 'reedsolomon/reed_solomon_codec.dart';

/// Decodes parity packets and recovers missing data packets.
class FecDecoder {
  FecDecoder({ReedSolomonCodec? codec})
      : _codec = codec ?? const ReedSolomonCodec();

  final ReedSolomonCodec _codec;

  /// Attempts to recover missing data packets for all blocks.
  FecRecoveryResult recover({
    required FecConfiguration config,
    required String sessionId,
    required int totalChunks,
    required Map<int, DataPacket> receivedData,
    required Map<int, ParityPacket> receivedParity,
    required Set<int> missingChunkIds,
  }) {
    if (!config.enabled || missingChunkIds.isEmpty) {
      return const FecRecoveryResult();
    }
    if (config.codecType != FecCodecType.reedSolomon) {
      return const FecRecoveryResult();
    }

    final planner = const FecBlockPlanner();
    final plans = planner.planForRecovery(
      totalChunks: totalChunks,
      config: config,
      receivedData: receivedData,
    );
    if (plans.isEmpty) return const FecRecoveryResult();

    final recovered = <int, DataPacket>{};
    final unrecoverable = <int>[];
    final summaries = <FecBlockRecoverySummary>[];

    for (final plan in plans) {
      final blockMissing = plan.dataChunkIds
          .where((id) => missingChunkIds.contains(id))
          .toList();
      if (blockMissing.isEmpty) continue;

      final k = plan.dataCount;
      final m = plan.parityCount;
      final symbolLength = plan.symbolLength;

      final available = <int, Uint8List>{};
      final erasures = <int>[];

      for (var i = 0; i < k; i++) {
        final chunkId = plan.dataChunkIds[i];
        if (receivedData.containsKey(chunkId)) {
          available[i] = FecBlockPlanner.padPayload(
            receivedData[chunkId]!.payload,
            symbolLength,
          );
        } else {
          erasures.add(i);
        }
      }

      for (var i = 0; i < m; i++) {
        final parityId = plan.firstParityId + i;
        final parityIndex = k + i;
        if (receivedParity.containsKey(parityId)) {
          available[parityIndex] = receivedParity[parityId]!.payload;
        } else {
          erasures.add(parityIndex);
        }
      }

      if (erasures.length > m) {
        unrecoverable.add(plan.blockIndex);
        summaries.add(
          FecBlockRecoverySummary(
            blockIndex: plan.blockIndex,
            dataCount: k,
            parityCount: m,
            missingBefore: blockMissing.length,
            recoveredCount: 0,
            success: false,
          ),
        );
        continue;
      }

      final decoded = _codec.decodeBlock(
        dataCount: k,
        parityCount: m,
        symbolLength: symbolLength,
        erasures: erasures,
        available: available,
      );

      if (decoded == null) {
        unrecoverable.add(plan.blockIndex);
        summaries.add(
          FecBlockRecoverySummary(
            blockIndex: plan.blockIndex,
            dataCount: k,
            parityCount: m,
            missingBefore: blockMissing.length,
            recoveredCount: 0,
            success: false,
          ),
        );
        continue;
      }

      var blockRecovered = 0;
      for (var i = 0; i < k; i++) {
        final chunkId = plan.dataChunkIds[i];
        if (!missingChunkIds.contains(chunkId)) continue;

        final originalLen = _originalPayloadLength(
          chunkId: chunkId,
          totalChunks: totalChunks,
          symbolLength: symbolLength,
          receivedData: receivedData,
        );

        final payload = FecBlockPlanner.trimPayload(decoded[i], originalLen);
        recovered[chunkId] = DataPacket(
          sessionId: sessionId,
          chunkId: chunkId,
          totalChunks: totalChunks,
          payload: payload,
        );
        blockRecovered++;
      }

      summaries.add(
        FecBlockRecoverySummary(
          blockIndex: plan.blockIndex,
          dataCount: k,
          parityCount: m,
          missingBefore: blockMissing.length,
          recoveredCount: blockRecovered,
          success: blockRecovered == blockMissing.length,
        ),
      );
    }

    return FecRecoveryResult(
      recovered: recovered,
      unrecoverableBlocks: unrecoverable,
      blockSummaries: summaries,
      success: recovered.isNotEmpty,
    );
  }

  int _originalPayloadLength({
    required int chunkId,
    required int totalChunks,
    required int symbolLength,
    required Map<int, DataPacket> receivedData,
  }) {
    if (receivedData.containsKey(chunkId)) {
      return receivedData[chunkId]!.payload.length;
    }
    return symbolLength;
  }
}
