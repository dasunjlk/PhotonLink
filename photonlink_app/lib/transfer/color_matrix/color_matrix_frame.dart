import 'dart:typed_data';

/// A single RGB cell in the color matrix grid.
class ColorCell {
  const ColorCell({
    required this.r,
    required this.g,
    required this.b,
    this.value,
  });

  final int r;
  final int g;
  final int b;
  final int? value;

  @override
  bool operator ==(Object other) =>
      other is ColorCell && r == other.r && g == other.g && b == other.b;

  @override
  int get hashCode => Object.hash(r, g, b);
}

/// Transport frame for Color Matrix optical encoding (PLCM v1).
///
/// See docs/COLOR_MATRIX_FORMAT.md for wire format details.
class ColorMatrixFrame {
  const ColorMatrixFrame({
    required this.protocolVersion,
    required this.sessionId,
    required this.frameId,
    required this.packetId,
    required this.isMetadata,
    required this.totalPackets,
    required this.payload,
    required this.checksum,
    required this.gridSize,
    this.bitsPerChannel = 2,
    this.cells = const [],
    this.rasterBytes,
  });

  static const int currentProtocolVersion = 1;
  static const String magic = 'PLCM';

  final int protocolVersion;
  final String sessionId;
  final int frameId;
  final int packetId;
  final bool isMetadata;
  final int totalPackets;
  final Uint8List payload;
  final int checksum;
  final int gridSize;
  final int bitsPerChannel;
  final List<ColorCell> cells;
  final Uint8List? rasterBytes;

  int get bitsPerCell => bitsPerChannel * 3;

  ColorMatrixFrame copyWith({
    List<ColorCell>? cells,
    Uint8List? rasterBytes,
  }) {
    return ColorMatrixFrame(
      protocolVersion: protocolVersion,
      sessionId: sessionId,
      frameId: frameId,
      packetId: packetId,
      isMetadata: isMetadata,
      totalPackets: totalPackets,
      payload: payload,
      checksum: checksum,
      gridSize: gridSize,
      bitsPerChannel: bitsPerChannel,
      cells: cells ?? this.cells,
      rasterBytes: rasterBytes ?? this.rasterBytes,
    );
  }
}
