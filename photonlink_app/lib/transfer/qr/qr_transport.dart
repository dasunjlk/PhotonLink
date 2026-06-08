import 'dart:typed_data';

import '../../protocols/interfaces/chunk_manager.dart';
import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transport.dart';
import '../../protocols/interfaces/transport_limits_resolver.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../protocols/transfer_method.dart';
import '../core/transfer_limits.dart';
import 'qr_frame_codec.dart';
import 'qr_transfer_limits.dart';

/// QR optical transport bundle.
class QrTransport implements Transport<String> {
  const QrTransport({
    QrFrameCodec? codec,
    QrTransferLimitsResolver? limits,
  })  : _codec = codec ?? const QrFrameCodec(),
        _limits = limits ?? const QrTransferLimitsResolver();

  final QrFrameCodec _codec;
  final QrTransferLimitsResolver _limits;

  @override
  TransferMethod get method => TransferMethod.qr;

  @override
  TransferEncoder<String> get encoder => _codec;

  @override
  TransferDecoder<String> get decoder => _codec;

  @override
  QrTransferLimitsResolver get limits => _limits;

  @override
  TransportCapabilities get capabilities => const TransportCapabilities(
        supportsCompression: true,
        supportsEncryption: true,
        supportsReliabilityFeedback: false,
        defaultFramesPerSecond: 2.0,
        maxFileBytes: TransferLimits.maxQrFileBytes,
      );
}

/// QR-specific [TransportLimitsResolver] implementation.
class QrTransferLimitsResolver implements TransportLimitsResolver<String> {
  const QrTransferLimitsResolver();

  @override
  String get transportLabel => 'QR transfer';

  @override
  int get maxFileBytes => TransferLimits.maxQrFileBytes;

  @override
  int resolveChunkSize({
    required String sessionId,
    required Uint8List fileBytes,
    required ChunkManager chunkManager,
    required TransferEncoder<String> encoder,
  }) {
    return QrTransferLimits.resolveChunkSize(
      sessionId: sessionId,
      fileBytes: fileBytes,
      chunkManager: chunkManager,
      encoder: encoder,
    );
  }

  @override
  bool allFramesFit({
    required String sessionId,
    required MetadataPacket metadata,
    required List<DataPacket> dataPackets,
    required TransferEncoder<String> encoder,
  }) {
    return QrTransferLimits.allDataFramesFit(
      sessionId,
      metadata,
      dataPackets,
      encoder,
    );
  }
}
