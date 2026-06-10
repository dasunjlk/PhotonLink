import '../../protocols/interfaces/transfer_packet.dart';
import 'fec_block_planner.dart';
import 'models/fec_codec_type.dart';
import 'models/fec_configuration.dart';
import 'reedsolomon/reed_solomon_codec.dart';

/// Generates parity packets from data packets using Reed-Solomon encoding.
class FecEncoder {
  FecEncoder({ReedSolomonCodec? codec}) : _codec = codec ?? const ReedSolomonCodec();

  final ReedSolomonCodec _codec;

  /// Encodes [dataPackets] into parity packets per [config].
  List<ParityPacket> encode({
    required List<DataPacket> dataPackets,
    required FecConfiguration config,
    required String sessionId,
    required int totalChunks,
  }) {
    if (!config.enabled || dataPackets.isEmpty) return [];
    if (config.codecType != FecCodecType.reedSolomon) {
      throw UnsupportedError(
        'Codec ${config.codecType.id} not implemented in Phase 7',
      );
    }

    final planner = const FecBlockPlanner();
    final plans = planner.plan(dataPackets: dataPackets, config: config);
    if (plans.isEmpty) return [];

    final packetMap = {for (final p in dataPackets) p.chunkId: p};
    final parityPackets = <ParityPacket>[];
    final totalParity = config.totalParityCount(totalChunks);

    for (final plan in plans) {
      final dataSymbols = plan.dataChunkIds.map((id) {
        final packet = packetMap[id]!;
        return FecBlockPlanner.padPayload(packet.payload, plan.symbolLength);
      }).toList();

      final paritySymbols = _codec.encodeBlock(
        dataSymbols: dataSymbols,
        parityCount: plan.parityCount,
        symbolLength: plan.symbolLength,
      );

      for (var i = 0; i < plan.parityCount; i++) {
        parityPackets.add(
          ParityPacket(
            sessionId: sessionId,
            parityId: plan.firstParityId + i,
            blockIndex: plan.blockIndex,
            parityIndexInBlock: i,
            dataCount: plan.dataCount,
            parityCount: plan.parityCount,
            dataSymbolLength: plan.symbolLength,
            totalParity: totalParity,
            totalChunks: totalChunks,
            payload: paritySymbols[i],
          ),
        );
      }
    }

    return parityPackets;
  }
}
