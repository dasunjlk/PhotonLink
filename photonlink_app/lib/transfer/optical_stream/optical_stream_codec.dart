import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../../services/core/packet_service.dart';
import '../fec/parity_payload_codec.dart';
import 'optical_brightness_decoder.dart';
import 'optical_brightness_encoder.dart';
import 'optical_pattern.dart';
import 'optical_stream_frame.dart';
import 'optical_stream_serializer.dart';

/// Maps [TransferPacket]s to [OpticalStreamFrame]s and back.
class OpticalStreamFrameCodec
    implements
        TransferEncoder<OpticalStreamFrame>,
        TransferDecoder<OpticalStreamFrame> {
  OpticalStreamFrameCodec({
    this.gridSize = 24,
    this.bitsPerCell = 1,
    this.streamId = 1,
    OpticalBrightnessEncoder? encoder,
    OpticalBrightnessDecoder? decoder,
    PacketService? packetService,
  })  : _encoder = encoder ?? OpticalBrightnessEncoder(bitsPerCell: bitsPerCell),
        _decoder = decoder ?? OpticalBrightnessDecoder(bitsPerCell: bitsPerCell),
        _packetService = packetService;

  final int gridSize;
  final int bitsPerCell;
  final int streamId;
  final OpticalBrightnessEncoder _encoder;
  final OpticalBrightnessDecoder _decoder;
  final PacketService? _packetService;
  int _frameCounter = 0;

  String? encoderKeyExchangePayload;
  bool _keyExchangeDelivered = false;
  String? lastDecodedKeyExchange;

  int get maxPayloadBytes => OpticalPattern.maxPayloadBytes(gridSize, bitsPerCell);

  void resetFrameCounter() {
    _frameCounter = 0;
    _keyExchangeDelivered = false;
  }

  @override
  OpticalStreamFrame encodeFrame(TransferPacket packet) {
    final frameId = _frameCounter++;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    late final Uint8List payload;
    late final OpticalStreamPacketType packetType;
    late final int packetId;
    late final int totalPackets;

    switch (packet) {
      case MetadataPacket metadata:
        packetType = OpticalStreamPacketType.metadata;
        packetId = 0;
        totalPackets = metadata.totalChunks;
        final keyPayload = !_keyExchangeDelivered
            ? encoderKeyExchangePayload
            : null;
        if (keyPayload != null) {
          _keyExchangeDelivered = true;
        }
        payload = Uint8List.fromList(
          utf8.encode(
            jsonEncode(
              _metadataToJson(
                metadata,
                keyExchangePayload: keyPayload,
              ),
            ),
          ),
        );
      case DataPacket data:
        packetType = OpticalStreamPacketType.data;
        packetId = data.chunkId;
        totalPackets = data.totalChunks;
        payload = data.payload;
      case ParityPacket parity:
        packetType = OpticalStreamPacketType.parity;
        packetId = parity.parityId;
        totalPackets = parity.totalParity;
        payload = ParityPayloadCodec.encodeBytes(parity);
      default:
        throw StateError('Unsupported packet type for Optical Stream: $packet');
    }

    final frame = OpticalStreamFrame(
      protocolVersion: OpticalStreamFrame.currentProtocolVersion,
      sessionId: packet.sessionId,
      streamId: streamId,
      frameId: frameId,
      packetId: packetId,
      packetType: packetType,
      totalPackets: totalPackets,
      payload: payload,
      checksum: 0,
      syncMarker: OpticalStreamFrame.defaultSyncMarker,
      timestamp: nowMs,
      gridSize: gridSize,
      bitsPerCell: bitsPerCell,
    );

    final serialized = _serializeFrame(frame);
    final capacity = maxSerializedBytes;
    if (serialized.length > capacity) {
      throw StateError(
        'Serialized frame too large (${serialized.length} bytes) for '
        '${gridSize}x$gridSize grid (capacity $capacity)',
      );
    }

    final cells = _encoder.encodeBytes(serialized, gridSize: gridSize);
    final decoded = _deserializeFrame(serialized);

    return OpticalStreamFrame(
      protocolVersion: OpticalStreamFrame.currentProtocolVersion,
      sessionId: packet.sessionId,
      streamId: streamId,
      frameId: frameId,
      packetId: packetId,
      packetType: packetType,
      totalPackets: totalPackets,
      payload: payload,
      checksum: decoded?.checksum ?? 0,
      syncMarker: OpticalStreamFrame.defaultSyncMarker,
      timestamp: nowMs,
      gridSize: gridSize,
      bitsPerCell: bitsPerCell,
      cells: cells,
    );
  }

  @override
  TransferPacket? decodeFrame(OpticalStreamFrame raw) {
    if (raw.cells.isEmpty) return null;

    OpticalStreamFrame? frame;
    try {
      for (var len = maxSerializedBytes; len >= 32; len--) {
        final bytes = _decoder.decodeCells(raw.cells, expectedByteLength: len);
        if (!bytes.valid) continue;
        frame = _deserializeFrame(bytes.frameBytes);
        if (frame != null) break;
      }
    } catch (_) {
      return null;
    }
    if (frame == null) return null;

    if (frame.packetType == OpticalStreamPacketType.metadata) {
      try {
        final jsonStr = utf8.decode(frame.payload);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        lastDecodedKeyExchange = map['keyExchangePayload'] as String?;
        return _metadataFromJson(frame.sessionId, map);
      } catch (_) {
        return null;
      }
    }

    if (frame.packetType == OpticalStreamPacketType.parity) {
      return ParityPayloadCodec.decodeBytes(frame.sessionId, frame.payload);
    }

    return DataPacket(
      sessionId: frame.sessionId,
      chunkId: frame.packetId,
      totalChunks: frame.totalPackets,
      payload: frame.payload,
    );
  }

  int get maxSerializedBytes => maxPayloadBytes;

  Uint8List _serializeFrame(OpticalStreamFrame frame) {
    if (_packetService != null) {
      return _packetService!.serializePlosFrame(frame);
    }
    return OpticalStreamSerializer.serialize(frame);
  }

  OpticalStreamFrame? _deserializeFrame(Uint8List bytes) {
    if (_packetService != null) {
      return _packetService!.deserializePlosFrame(bytes);
    }
    return OpticalStreamSerializer.deserialize(bytes);
  }

  static Map<String, dynamic> _metadataToJson(
    MetadataPacket metadata, {
    String? keyExchangePayload,
  }) {
    return {
      'fileName': metadata.fileName,
      'fileSize': metadata.fileSize,
      'totalChunks': metadata.totalChunks,
      'sha256': metadata.sha256,
      'mimeType': metadata.mimeType,
      'protocolVersion': metadata.protocolVersion,
      'compression': metadata.compression.name,
      'encryption': metadata.encryption.name,
      if (metadata.originalSize != null) 'originalSize': metadata.originalSize,
      if (metadata.originalSha256 != null)
        'originalSha256': metadata.originalSha256,
      if (keyExchangePayload != null) 'keyExchangePayload': keyExchangePayload,
    };
  }

  static MetadataPacket _metadataFromJson(
    String sessionId,
    Map<String, dynamic> json,
  ) {
    return MetadataPacket(
      sessionId: sessionId,
      fileName: json['fileName'] as String? ?? 'unknown',
      fileSize: json['fileSize'] as int? ?? 0,
      totalChunks: json['totalChunks'] as int? ?? 0,
      sha256: json['sha256'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      protocolVersion: json['protocolVersion'] as int? ?? 1,
      compression: CompressionType.values.firstWhere(
        (v) => v.name == json['compression'],
        orElse: () => CompressionType.none,
      ),
      encryption: EncryptionMode.values.firstWhere(
        (v) => v.name == json['encryption'],
        orElse: () => EncryptionMode.disabled,
      ),
      originalSize: json['originalSize'] as int?,
      originalSha256: json['originalSha256'] as String?,
    );
  }
}
