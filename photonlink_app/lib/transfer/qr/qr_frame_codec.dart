import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';

/// QR wire format: PL2|<type>|<sessionId>|<seq>|<total>|<base64Payload>
class QrFrameCodec implements TransferEncoder<String>, TransferDecoder<String> {
  const QrFrameCodec();

  static const String magic = 'PL2';

  @override
  String encodeFrame(TransferPacket packet) {
    final frame = _encodeFrameUnchecked(packet);
    if (frame.length > TransferLimits.maxQrFrameChars) {
      throw TransferLimitException(
        'QR frame too large (${frame.length} chars, max ${TransferLimits.maxQrFrameChars})',
      );
    }
    return frame;
  }

  String _encodeFrameUnchecked(TransferPacket packet) {
    switch (packet) {
      case MetadataPacket metadata:
        final b64 = base64Encode(utf8.encode(jsonEncode(metadata.toJson())));
        return '$magic|M|${metadata.sessionId}|0|${metadata.totalChunks}|$b64';
      case DataPacket data:
        final b64 = base64Encode(data.payload);
        return '$magic|D|${data.sessionId}|${data.chunkId}|${data.totalChunks}|$b64';
    }
  }

  @override
  TransferPacket? decodeFrame(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('$magic|')) return null;
    if (trimmed.length > TransferLimits.maxQrFrameChars * 2) return null;

    final parts = trimmed.split('|');
    if (parts.length != 6) return null;

    final type = parts[1];
    final sessionId = parts[2];
    if (sessionId.isEmpty || sessionId.length > 128) return null;

    final seq = int.tryParse(parts[3]);
    final total = int.tryParse(parts[4]);
    if (seq == null || total == null) return null;
    if (total < 1 || total > TransferLimits.maxTotalChunks) return null;

    try {
      final payloadBytes = base64Decode(parts[5]);
      if (type == 'M') {
        final jsonMap =
            jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
        final metadata = MetadataPacket.fromJson(sessionId, jsonMap);
        TransferLimits.validateMetadata(
          fileName: metadata.fileName,
          fileSize: metadata.fileSize,
          totalChunks: metadata.totalChunks,
          sha256: metadata.sha256,
        );
        return metadata;
      } else if (type == 'D') {
        if (seq < 0 || seq >= total) return null;
        if (payloadBytes.length > TransferLimits.maxColorMatrixFileBytes) {
          return null;
        }
        return DataPacket(
          sessionId: sessionId,
          chunkId: seq,
          totalChunks: total,
          payload: Uint8List.fromList(payloadBytes),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
