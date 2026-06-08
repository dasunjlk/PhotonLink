import 'dart:convert';
import 'dart:typed_data';

import 'color_matrix_frame.dart';

/// Serializes and deserializes [ColorMatrixFrame] binary payloads.
abstract final class ColorMatrixSerializer {
  static Uint8List serialize(ColorMatrixFrame frame) {
    final sessionBytes = utf8.encode(frame.sessionId);
    final buffer = BytesBuilder();
    buffer.add(utf8.encode(ColorMatrixFrame.magic));
    buffer.addByte(frame.protocolVersion);
    buffer.addByte(frame.isMetadata ? 0 : 1);
    buffer.addByte(sessionBytes.length);
    buffer.add(sessionBytes);
    buffer.add(_uint32(frame.frameId));
    buffer.add(_uint32(frame.packetId));
    buffer.add(_uint32(frame.totalPackets));
    buffer.add(_uint32(frame.gridSize));
    buffer.addByte(frame.bitsPerChannel);
    buffer.add(_uint32(frame.payload.length));
    buffer.add(frame.payload);

    final body = buffer.toBytes();
    final checksum = _crc32(body);
    return Uint8List.fromList(body + _uint32(checksum));
  }

  static ColorMatrixFrame? deserialize(Uint8List bytes) {
    if (bytes.length < 24) return null;
    try {
      if (utf8.decode(bytes.sublist(0, 4)) != ColorMatrixFrame.magic) return null;
    } catch (_) {
      return null;
    }

    var offset = 4;
    final version = bytes[offset++];
    final isMetadata = bytes[offset++] == 0;
    final sessionLen = bytes[offset++];
    if (offset + sessionLen > bytes.length) return null;
    late final String sessionId;
    try {
      sessionId = utf8.decode(bytes.sublist(offset, offset + sessionLen));
    } catch (_) {
      return null;
    }
    offset += sessionLen;

    int readU32() {
      final v = bytes[offset] << 24 |
          bytes[offset + 1] << 16 |
          bytes[offset + 2] << 8 |
          bytes[offset + 3];
      offset += 4;
      return v;
    }

    final frameId = readU32();
    final packetId = readU32();
    final totalPackets = readU32();
    final gridSize = readU32();
    if (offset >= bytes.length) return null;
    final bitsPerChannel = bytes[offset++];
    final payloadLen = readU32();
    if (offset + payloadLen + 4 > bytes.length) return null;
    final payload = Uint8List.fromList(
      bytes.sublist(offset, offset + payloadLen),
    );
    offset += payloadLen;
    final checksum = readU32();

    final body = bytes.sublist(0, offset - 4);
    if (_crc32(body) != checksum) return null;

    return ColorMatrixFrame(
      protocolVersion: version,
      sessionId: sessionId,
      frameId: frameId,
      packetId: packetId,
      isMetadata: isMetadata,
      totalPackets: totalPackets,
      payload: payload,
      checksum: checksum,
      gridSize: gridSize,
      bitsPerChannel: bitsPerChannel,
    );
  }

  static int serializedLength(ColorMatrixFrame frame) {
    return serialize(frame).length;
  }

  static List<int> _uint32(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static int _crc32(Uint8List data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return (~crc) & 0xFFFFFFFF;
  }
}
