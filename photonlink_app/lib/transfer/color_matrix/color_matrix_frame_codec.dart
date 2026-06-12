import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import '../../protocols/interfaces/encryption_mode.dart';
import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
import '../fec/parity_payload_codec.dart';
import 'color_decoder.dart';
import 'color_encoder.dart';
import 'color_matrix_frame.dart';
import 'color_matrix_serializer.dart';

/// Maps [TransferPacket]s to [ColorMatrixFrame]s and back.
class ColorMatrixFrameCodec
    implements
        TransferEncoder<ColorMatrixFrame>,
        TransferDecoder<ColorMatrixFrame> {
  ColorMatrixFrameCodec({
    this.gridSize = 16,
    this.bitsPerChannel = 2,
    ColorEncoder? encoder,
    ColorDecoder? decoder,
  })  : _encoder = encoder ?? ColorEncoder(bitsPerChannel: bitsPerChannel),
        _decoder = decoder ?? ColorDecoder(bitsPerChannel: bitsPerChannel);

  final int gridSize;
  final int bitsPerChannel;
  final ColorEncoder _encoder;
  final ColorDecoder _decoder;
  int _frameCounter = 0;

  /// Embedded in metadata JSON when encryption is enabled (Color Matrix has no setup QR).
  String? encoderKeyExchangePayload;
  bool _keyExchangeDelivered = false;

  /// Populated after decoding a metadata frame that carries a session key.
  String? lastDecodedKeyExchange;

  int get maxPayloadBytes => _maxPayloadForGrid(gridSize, bitsPerChannel);

  void resetFrameCounter() {
    _frameCounter = 0;
    _keyExchangeDelivered = false;
  }

  @override
  ColorMatrixFrame encodeFrame(TransferPacket packet) {
    final frameId = _frameCounter++;
    late final Uint8List payload;
    late final ColorMatrixPacketType packetType;
    late final int packetId;
    late final int totalPackets;

    switch (packet) {
      case MetadataPacket metadata:
        packetType = ColorMatrixPacketType.metadata;
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
        packetType = ColorMatrixPacketType.data;
        packetId = data.chunkId;
        totalPackets = data.totalChunks;
        payload = data.payload;
      case ParityPacket parity:
        packetType = ColorMatrixPacketType.parity;
        packetId = parity.parityId;
        totalPackets = parity.totalParity;
        payload = ParityPayloadCodec.encodeBytes(parity);
      default:
        throw StateError('Unsupported packet type for Color Matrix: $packet');
    }

    final serialized = ColorMatrixSerializer.serialize(
      ColorMatrixFrame(
        protocolVersion: ColorMatrixFrame.currentProtocolVersion,
        sessionId: packet.sessionId,
        frameId: frameId,
        packetId: packetId,
        packetType: packetType,
        totalPackets: totalPackets,
        payload: payload,
        checksum: 0,
        gridSize: gridSize,
        bitsPerChannel: bitsPerChannel,
      ),
    );

    final capacity = maxSerializedBytes;
    if (serialized.length > capacity) {
      throw StateError(
        'Serialized frame too large (${serialized.length} bytes) for '
        '${gridSize}x$gridSize grid (capacity $capacity)',
      );
    }

    final cells = _encoder.encodeBytes(serialized, gridSize: gridSize);
    final decoded = ColorMatrixSerializer.deserialize(serialized);

    return ColorMatrixFrame(
      protocolVersion: ColorMatrixFrame.currentProtocolVersion,
      sessionId: packet.sessionId,
      frameId: frameId,
      packetId: packetId,
      packetType: packetType,
      totalPackets: totalPackets,
      payload: payload,
      checksum: decoded?.checksum ?? 0,
      gridSize: gridSize,
      bitsPerChannel: bitsPerChannel,
      cells: cells,
    );
  }

  @override
  TransferPacket? decodeFrame(ColorMatrixFrame raw) {
    if (raw.cells.isEmpty) return null;

    ColorMatrixFrame? frame;
    try {
      for (var len = maxSerializedBytes; len >= 24; len--) {
        final bytes = _decoder.decodeCells(raw.cells, expectedByteLength: len);
        if (!bytes.valid) continue;
        frame = ColorMatrixSerializer.deserialize(bytes.frameBytes);
        if (frame != null) break;
      }
    } catch (_) {
      return null;
    }
    if (frame == null) return null;

    if (frame.sessionId != raw.sessionId && raw.sessionId.isNotEmpty) {
      // Allow session from detected frame header
    }

    if (frame.packetType == ColorMatrixPacketType.metadata) {
      try {
        final jsonStr = utf8.decode(frame.payload);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        lastDecodedKeyExchange = map['keyExchangePayload'] as String?;
        return _metadataFromJson(frame.sessionId, map);
      } catch (_) {
        return null;
      }
    }

    if (frame.packetType == ColorMatrixPacketType.parity) {
      return ParityPayloadCodec.decodeBytes(frame.sessionId, frame.payload);
    }

    return DataPacket(
      sessionId: frame.sessionId,
      chunkId: frame.packetId,
      totalChunks: frame.totalPackets,
      payload: frame.payload,
    );
  }

  int get maxSerializedBytes => _maxPayloadForGrid(gridSize, bitsPerChannel);

  static int _maxPayloadForGrid(int gridSize, int bitsPerChannel) {
    final bitsPerCell = bitsPerChannel * 3;
    final totalBits = gridSize * gridSize * bitsPerCell;
    return totalBits ~/ 8;
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
