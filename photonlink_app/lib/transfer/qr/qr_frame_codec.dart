import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';

/// QR wire format: PL2|<type>|<sessionId>|<seq>|<total>|<base64Payload>
class QrFrameCodec implements TransferEncoder, TransferDecoder {
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
        final jsonPayload = jsonEncode({
          'fileName': metadata.fileName,
          'fileSize': metadata.fileSize,
          'totalChunks': metadata.totalChunks,
          'sha256': metadata.sha256,
          'mimeType': metadata.mimeType,
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
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
        final fileName = jsonMap['fileName'] as String? ?? '';
        final fileSize = jsonMap['fileSize'] as int? ?? -1;
        final totalChunks = jsonMap['totalChunks'] as int? ?? 0;
        final sha256 = jsonMap['sha256'] as String? ?? '';
        TransferLimits.validateMetadata(
          fileName: fileName,
          fileSize: fileSize,
          totalChunks: totalChunks,
          sha256: sha256,
        );
        return MetadataPacket(
          sessionId: sessionId,
          fileName: fileName,
          fileSize: fileSize,
          totalChunks: totalChunks,
          sha256: sha256,
          mimeType:
              jsonMap['mimeType'] as String? ?? 'application/octet-stream',
        );
      } else if (type == 'D') {
        if (seq < 0 || seq >= total) return null;
        if (payloadBytes.length > TransferLimits.maxFileBytes) return null;
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
