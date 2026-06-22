import 'dart:convert';
import 'dart:typed_data';

import 'optical_stream_frame.dart';

/// Binary PLOS wire serializer (matches Rust `packet::plos`).
abstract final class OpticalStreamSerializer {
  static Uint8List serialize(OpticalStreamFrame frame) {
    final sessionBytes = utf8.encode(frame.sessionId);
    final buffer = BytesBuilder();
    buffer.add(utf8.encode(OpticalStreamFrame.magic));
    buffer.addByte(frame.protocolVersion);
    buffer.addByte(frame.packetType.value);
    buffer.addByte(sessionBytes.length);
    buffer.add(sessionBytes);
    buffer.add(_uint16(frame.streamId));
    buffer.add(_uint32(frame.frameId));
    buffer.add(_uint32(frame.packetId));
    buffer.add(_uint32(frame.totalPackets));
    buffer.add(_uint16(frame.syncMarker));
    buffer.add(_uint64(frame.timestamp));
    buffer.add(_uint32(frame.gridSize));
    buffer.addByte(frame.bitsPerCell);
    buffer.add(_uint32(frame.payload.length));
    buffer.add(frame.payload);

    final body = buffer.toBytes();
    final checksum = _crc32(body);
    return Uint8List.fromList(body + _uint32(checksum));
  }

  static OpticalStreamFrame? deserialize(Uint8List bytes) {
    if (bytes.length < 32) return null;
    try {
      if (utf8.decode(bytes.sublist(0, 4)) != OpticalStreamFrame.magic) {
        return null;
      }
    } catch (_) {
      return null;
    }

    var offset = 4;
    final version = bytes[offset++];
    final packetTypeValue = bytes[offset++];
    final packetType = OpticalStreamPacketType.fromValue(packetTypeValue);
    final sessionLen = bytes[offset++];
    if (offset + sessionLen > bytes.length) return null;
    late final String sessionId;
    try {
      sessionId = utf8.decode(bytes.sublist(offset, offset + sessionLen));
    } catch (_) {
      return null;
    }
    offset += sessionLen;

    int readU16() {
      final v = (bytes[offset] << 8) | bytes[offset + 1];
      offset += 2;
      return v;
    }

    int readU32() {
      final v = bytes[offset] << 24 |
          bytes[offset + 1] << 16 |
          bytes[offset + 2] << 8 |
          bytes[offset + 3];
      offset += 4;
      return v;
    }

    int readU64() {
      var v = 0;
      for (var i = 0; i < 8; i++) {
        v = (v << 8) | bytes[offset++];
      }
      return v;
    }

    final streamId = readU16();
    final frameId = readU32();
    final packetId = readU32();
    final totalPackets = readU32();
    final syncMarker = readU16();
    final timestamp = readU64();
    final gridSize = readU32();
    if (offset >= bytes.length) return null;
    final bitsPerCell = bytes[offset++];
    final payloadLen = readU32();
    if (offset + payloadLen + 4 > bytes.length) return null;
    final payload = Uint8List.fromList(
      bytes.sublist(offset, offset + payloadLen),
    );
    offset += payloadLen;
    final checksum = readU32();

    final body = bytes.sublist(0, offset - 4);
    if (_crc32(body) != checksum) return null;

    return OpticalStreamFrame(
      protocolVersion: version,
      sessionId: sessionId,
      streamId: streamId,
      frameId: frameId,
      packetId: packetId,
      packetType: packetType,
      totalPackets: totalPackets,
      payload: payload,
      checksum: checksum,
      syncMarker: syncMarker,
      timestamp: timestamp,
      gridSize: gridSize,
      bitsPerCell: bitsPerCell,
    );
  }

  static int serializedLength(OpticalStreamFrame frame) {
    return serialize(frame).length;
  }

  static List<int> _uint16(int value) => [
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static List<int> _uint32(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  static List<int> _uint64(int value) => [
        (value >> 56) & 0xFF,
        (value >> 48) & 0xFF,
        (value >> 40) & 0xFF,
        (value >> 32) & 0xFF,
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
