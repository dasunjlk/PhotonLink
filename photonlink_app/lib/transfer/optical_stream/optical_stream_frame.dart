import 'dart:typed_data';

/// A single brightness cell in the optical stream grid (binary: 0=dark, 1=light).
class BrightnessCell {
  const BrightnessCell({required this.brightness, this.bit});

  /// 0.0 = black, 1.0 = white.
  final double brightness;
  final int? bit;

  bool get isLight => brightness >= 0.5;

  @override
  bool operator ==(Object other) =>
      other is BrightnessCell && brightness == other.brightness;

  @override
  int get hashCode => brightness.hashCode;
}

/// Packet type for Optical Stream frames (PLOS v1).
enum OpticalStreamPacketType {
  metadata(0),
  data(1),
  parity(2);

  const OpticalStreamPacketType(this.value);

  final int value;

  static OpticalStreamPacketType fromValue(int value) {
    return OpticalStreamPacketType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => OpticalStreamPacketType.data,
    );
  }

  bool get isMetadata => this == OpticalStreamPacketType.metadata;
}

/// Transport frame for Optical Stream continuous encoding (PLOS v1).
///
/// See docs/OPTICAL_STREAM_FORMAT.md for wire format details.
class OpticalStreamFrame {
  const OpticalStreamFrame({
    required this.protocolVersion,
    required this.sessionId,
    required this.streamId,
    required this.frameId,
    required this.packetId,
    required this.packetType,
    required this.totalPackets,
    required this.payload,
    required this.checksum,
    required this.syncMarker,
    required this.timestamp,
    required this.gridSize,
    this.bitsPerCell = 1,
    this.cells = const [],
    this.rasterBytes,
  });

  static const int currentProtocolVersion = 1;
  static const String magic = 'PLOS';
  static const int defaultSyncMarker = 0xA55A;

  final int protocolVersion;
  final String sessionId;
  final int streamId;
  final int frameId;
  final int packetId;
  final OpticalStreamPacketType packetType;
  final int totalPackets;
  final Uint8List payload;
  final int checksum;
  final int syncMarker;
  final int timestamp;
  final int gridSize;
  final int bitsPerCell;
  final List<BrightnessCell> cells;
  final Uint8List? rasterBytes;

  bool get isMetadata => packetType.isMetadata;

  OpticalStreamFrame copyWith({
    List<BrightnessCell>? cells,
    Uint8List? rasterBytes,
  }) {
    return OpticalStreamFrame(
      protocolVersion: protocolVersion,
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
      cells: cells ?? this.cells,
      rasterBytes: rasterBytes ?? this.rasterBytes,
    );
  }
}
