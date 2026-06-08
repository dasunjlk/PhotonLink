import 'dart:convert';
import 'dart:typed_data';

import '../../core/constants.dart';
import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../core/transfer_limits.dart';
import '../serialization/packet_id_ranges.dart';

/// QR wire format: PL2|<type>|<sessionId>|<seq>|<total>|<base64Payload>
/// Types: S setup, M metadata, D data, A ack, N nak, H handshake, C control
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
      case SessionSetupPacket setup:
        final jsonPayload = jsonEncode({
          'protocolVersion': setup.protocolVersion,
          'keyExchangePayload': setup.keyExchangePayload,
          'compression': setup.compression.id,
          'encryption': setup.encryption.id,
          'timestamp': setup.timestamp.toIso8601String(),
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|S|${setup.sessionId}|0|1|$b64';
      case MetadataPacket metadata:
        final jsonPayload = jsonEncode({
          'fileName': metadata.fileName,
          'fileSize': metadata.fileSize,
          'totalChunks': metadata.totalChunks,
          'sha256': metadata.sha256,
          'mimeType': metadata.mimeType,
          'protocolVersion': metadata.protocolVersion,
          'compression': metadata.compression.id,
          'encryption': metadata.encryption.id,
          if (metadata.originalSize != null)
            'originalSize': metadata.originalSize,
          if (metadata.originalSha256 != null)
            'originalSha256': metadata.originalSha256,
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|M|${metadata.sessionId}|0|${metadata.totalChunks}|$b64';
      case DataPacket data:
        final b64 = base64Encode(data.payload);
        return '$magic|D|${data.sessionId}|${data.chunkId}|${data.totalChunks}|$b64';
      case AckPacket ack:
        final jsonPayload = jsonEncode({
          'packetIds': PacketIdRanges.encode(ack.packetIds),
          'timestamp': ack.timestamp.toIso8601String(),
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|A|${ack.sessionId}|0|${ack.packetIds.length}|$b64';
      case NakPacket nak:
        final jsonPayload = jsonEncode({
          'missingPacketIds': PacketIdRanges.encode(nak.missingPacketIds),
          'timestamp': nak.timestamp.toIso8601String(),
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|N|${nak.sessionId}|0|${nak.missingPacketIds.length}|$b64';
      case HandshakePacket handshake:
        final jsonPayload = jsonEncode({
          'receivedChunkIds':
              PacketIdRanges.encode(handshake.receivedChunkIds),
          'timestamp': handshake.timestamp.toIso8601String(),
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|H|${handshake.sessionId}|0|${handshake.receivedChunkIds.length}|$b64';
      case ControlPacket control:
        final jsonPayload = jsonEncode({
          'type': control.type.name,
          'timestamp': control.timestamp.toIso8601String(),
        });
        final b64 = base64Encode(utf8.encode(jsonPayload));
        return '$magic|C|${control.sessionId}|0|1|$b64';
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

    try {
      final payloadBytes = base64Decode(parts[5]);

      switch (type) {
        case 'D':
          if (total < 1 || total > TransferLimits.maxTotalChunks) return null;
          if (seq < 0 || seq >= total) return null;
          if (payloadBytes.length > TransferLimits.maxFileBytes) return null;
          return DataPacket(
            sessionId: sessionId,
            chunkId: seq,
            totalChunks: total,
            payload: Uint8List.fromList(payloadBytes),
          );
        case 'S':
          final jsonStr = utf8.decode(payloadBytes);
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          return SessionSetupPacket(
            sessionId: sessionId,
            protocolVersion:
                jsonMap['protocolVersion'] as int? ?? AppConstants.protocolVersion,
            keyExchangePayload:
                jsonMap['keyExchangePayload'] as String? ?? '',
            compression: CompressionType.fromId(
              jsonMap['compression'] as String?,
            ),
            encryption: EncryptionMode.fromId(
              jsonMap['encryption'] as String?,
            ),
            timestamp: DateTime.parse(
              jsonMap['timestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            ),
          );
        case 'M':
          final jsonStr = utf8.decode(payloadBytes);
          if (total < 1 || total > TransferLimits.maxTotalChunks) return null;
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
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
            protocolVersion: jsonMap['protocolVersion'] as int? ?? 1,
            compression: CompressionType.fromId(
              jsonMap['compression'] as String?,
            ),
            encryption: EncryptionMode.fromId(
              jsonMap['encryption'] as String?,
            ),
            originalSize: jsonMap['originalSize'] as int?,
            originalSha256: jsonMap['originalSha256'] as String?,
          );
        case 'A':
          final jsonStr = utf8.decode(payloadBytes);
          final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
          final ids = _decodeIdField(jsonMap['packetIds']);
          return AckPacket(
            sessionId: sessionId,
            packetIds: ids,
            timestamp: DateTime.parse(
              jsonMap['timestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            ),
          );
        case 'N':
          final jsonStrN = utf8.decode(payloadBytes);
          final jsonMap = jsonDecode(jsonStrN) as Map<String, dynamic>;
          final ids = _decodeIdField(jsonMap['missingPacketIds']);
          if (ids.length > TransferLimits.maxTotalChunks) return null;
          return NakPacket(
            sessionId: sessionId,
            missingPacketIds: ids,
            timestamp: DateTime.parse(
              jsonMap['timestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            ),
          );
        case 'H':
          final jsonStrH = utf8.decode(payloadBytes);
          final jsonMap = jsonDecode(jsonStrH) as Map<String, dynamic>;
          final ids = _decodeIdField(jsonMap['receivedChunkIds']);
          return HandshakePacket(
            sessionId: sessionId,
            receivedChunkIds: ids,
            timestamp: DateTime.parse(
              jsonMap['timestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            ),
          );
        case 'C':
          final jsonStrC = utf8.decode(payloadBytes);
          final jsonMap = jsonDecode(jsonStrC) as Map<String, dynamic>;
          final typeName = jsonMap['type'] as String? ?? 'ready';
          final controlType = ControlType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => ControlType.ready,
          );
          return ControlPacket(
            sessionId: sessionId,
            type: controlType,
            timestamp: DateTime.parse(
              jsonMap['timestamp'] as String? ??
                  DateTime.now().toIso8601String(),
            ),
          );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static List<int> _decodeIdField(dynamic field) {
    if (field == null) return [];
    if (field is List) {
      return field.map((e) => e as int).toList();
    }
    if (field is String) {
      if (field.startsWith('[')) {
        final list = jsonDecode(field) as List<dynamic>;
        return list.map((e) => e as int).toList();
      }
      return PacketIdRanges.decode(field);
    }
    return [];
  }
}
