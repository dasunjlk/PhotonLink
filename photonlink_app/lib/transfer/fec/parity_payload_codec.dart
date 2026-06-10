import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/transfer_packet.dart';

/// Serializes parity packet metadata + payload for transport codecs.
abstract final class ParityPayloadCodec {
  static Map<String, dynamic> toJson(ParityPacket packet) {
    return {
      'parityId': packet.parityId,
      'blockIndex': packet.blockIndex,
      'parityIndexInBlock': packet.parityIndexInBlock,
      'dataCount': packet.dataCount,
      'parityCount': packet.parityCount,
      'dataSymbolLength': packet.dataSymbolLength,
      'totalParity': packet.totalParity,
      'totalChunks': packet.totalChunks,
      'parityData': base64Encode(packet.payload),
    };
  }

  static ParityPacket? fromJson(String sessionId, Map<String, dynamic> json) {
    try {
      final parityData = json['parityData'] as String?;
      if (parityData == null) return null;
      return ParityPacket(
        sessionId: sessionId,
        parityId: json['parityId'] as int? ?? 0,
        blockIndex: json['blockIndex'] as int? ?? 0,
        parityIndexInBlock: json['parityIndexInBlock'] as int? ?? 0,
        dataCount: json['dataCount'] as int? ?? 0,
        parityCount: json['parityCount'] as int? ?? 0,
        dataSymbolLength: json['dataSymbolLength'] as int? ?? 0,
        totalParity: json['totalParity'] as int? ?? 0,
        totalChunks: json['totalChunks'] as int? ?? 0,
        payload: base64Decode(parityData),
      );
    } catch (_) {
      return null;
    }
  }

  static Uint8List encodeBytes(ParityPacket packet) {
    return Uint8List.fromList(utf8.encode(jsonEncode(toJson(packet))));
  }

  static ParityPacket? decodeBytes(String sessionId, Uint8List bytes) {
    try {
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      return fromJson(sessionId, jsonMap);
    } catch (_) {
      return null;
    }
  }
}
