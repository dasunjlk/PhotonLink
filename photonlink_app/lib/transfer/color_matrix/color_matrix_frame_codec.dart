import 'dart:convert';
import 'dart:typed_data';

import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transfer_packet.dart';
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

  int get maxPayloadBytes => _maxPayloadForGrid(gridSize, bitsPerChannel);

  void resetFrameCounter() => _frameCounter = 0;

  @override
  ColorMatrixFrame encodeFrame(TransferPacket packet) {
    final frameId = _frameCounter++;
    late final Uint8List payload;
    late final bool isMetadata;
    late final int packetId;
    late final int totalPackets;

    switch (packet) {
      case MetadataPacket metadata:
        isMetadata = true;
        packetId = 0;
        totalPackets = metadata.totalChunks;
        payload = Uint8List.fromList(utf8.encode(jsonEncode(metadata.toJson())));
      case DataPacket data:
        isMetadata = false;
        packetId = data.chunkId;
        totalPackets = data.totalChunks;
        payload = data.payload;
    }

    final serialized = ColorMatrixSerializer.serialize(
      ColorMatrixFrame(
        protocolVersion: ColorMatrixFrame.currentProtocolVersion,
        sessionId: packet.sessionId,
        frameId: frameId,
        packetId: packetId,
        isMetadata: isMetadata,
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
      isMetadata: isMetadata,
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

    if (frame.isMetadata) {
      try {
        final jsonStr = utf8.decode(frame.payload);
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return MetadataPacket.fromJson(frame.sessionId, map);
      } catch (_) {
        return null;
      }
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
}
