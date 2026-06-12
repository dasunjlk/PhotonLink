import 'dart:typed_data';

/// Abstract FFI surface for the Rust core engine.
///
/// Implemented by [FrbCoreApi] when the native core is connected, or
/// [NotConnectedCoreApi] as a fallback.
abstract interface class PhotonLinkCoreApi {
  Future<String> coreVersion();
  String sha256Hex(Uint8List data);
  bool sha256Verify(Uint8List data, String expected);
  int crc32Compute(Uint8List data);
  bool crc32Validate(Uint8List data, int expected);

  String encodePl2DataFrame({
    required String sessionId,
    required int chunkId,
    required int totalChunks,
    required Uint8List payload,
  });

  Pl2FrameDto decodePl2Frame(String raw);

  Uint8List encodePlcmFrame(PlcmFrameDto frame);
  PlcmFrameDto decodePlcmFrame(Uint8List bytes);

  Uint8List encodePlosFrame(PlosFrameDto frame);
  PlosFrameDto decodePlosFrame(Uint8List bytes);

  List<DataChunkDto> chunkSplit({
    required Uint8List data,
    required String sessionId,
    int chunkSize,
  });

  Uint8List chunkMerge(List<DataChunkDto> chunks);

  CompressionOutputDto compressData(Uint8List input, String kind);
  CompressionOutputDto decompressData(
    Uint8List input, {
    required String kind,
    required int originalSize,
  });

  Uint8List encryptData(Uint8List plaintext, Uint8List sessionKey);
  Uint8List decryptData(Uint8List wire, Uint8List sessionKey);

  QualityScoreOutputDto calculateQualityScore(QualityScoreInputDto input);

  List<Uint8List> fecEncodeBlock({
    required List<Uint8List> dataSymbols,
    required int parityCount,
    required int symbolLength,
  });

  List<Uint8List>? fecDecodeBlock({
    required int dataCount,
    required int parityCount,
    required int symbolLength,
    required List<int> erasures,
    required Map<int, Uint8List> available,
  });
}

/// Thrown when Rust backend is selected but FRB bindings are not connected.
class RustCoreNotConnectedException implements Exception {
  const RustCoreNotConnectedException([this.message =
      'Rust core not connected. Install Rust toolchain and run '
      'flutter_rust_bridge_codegen generate.']);

  final String message;

  @override
  String toString() => 'RustCoreNotConnectedException: $message';
}

/// Fallback when FRB codegen has not been run.
class NotConnectedCoreApi implements PhotonLinkCoreApi {
  const NotConnectedCoreApi();

  Never _throw() => throw const RustCoreNotConnectedException();

  @override
  Future<String> coreVersion() async => _throw();

  @override
  String sha256Hex(Uint8List data) => _throw();

  @override
  bool sha256Verify(Uint8List data, String expected) => _throw();

  @override
  int crc32Compute(Uint8List data) => _throw();

  @override
  bool crc32Validate(Uint8List data, int expected) => _throw();

  @override
  String encodePl2DataFrame({
    required String sessionId,
    required int chunkId,
    required int totalChunks,
    required Uint8List payload,
  }) =>
      _throw();

  @override
  Pl2FrameDto decodePl2Frame(String raw) => _throw();

  @override
  Uint8List encodePlcmFrame(PlcmFrameDto frame) => _throw();

  @override
  PlcmFrameDto decodePlcmFrame(Uint8List bytes) => _throw();

  @override
  Uint8List encodePlosFrame(PlosFrameDto frame) => _throw();

  @override
  PlosFrameDto decodePlosFrame(Uint8List bytes) => _throw();

  @override
  List<DataChunkDto> chunkSplit({
    required Uint8List data,
    required String sessionId,
    int chunkSize = 512,
  }) =>
      _throw();

  @override
  Uint8List chunkMerge(List<DataChunkDto> chunks) => _throw();

  @override
  CompressionOutputDto compressData(Uint8List input, String kind) => _throw();

  @override
  CompressionOutputDto decompressData(
    Uint8List input, {
    required String kind,
    required int originalSize,
  }) =>
      _throw();

  @override
  Uint8List encryptData(Uint8List plaintext, Uint8List sessionKey) => _throw();

  @override
  Uint8List decryptData(Uint8List wire, Uint8List sessionKey) => _throw();

  @override
  QualityScoreOutputDto calculateQualityScore(QualityScoreInputDto input) =>
      _throw();

  @override
  List<Uint8List> fecEncodeBlock({
    required List<Uint8List> dataSymbols,
    required int parityCount,
    required int symbolLength,
  }) =>
      _throw();

  @override
  List<Uint8List>? fecDecodeBlock({
    required int dataCount,
    required int parityCount,
    required int symbolLength,
    required List<int> erasures,
    required Map<int, Uint8List> available,
  }) =>
      _throw();
}

/// DTO mirrors for Rust FFI (used by both Dart and Rust backends).
class Pl2FrameDto {
  const Pl2FrameDto({
    required this.packetType,
    required this.sessionId,
    required this.seq,
    required this.total,
    required this.payload,
  });

  final String packetType;
  final String sessionId;
  final int seq;
  final int total;
  final Uint8List payload;
}

class PlcmFrameDto {
  const PlcmFrameDto({
    required this.protocolVersion,
    required this.sessionId,
    required this.frameId,
    required this.packetId,
    required this.packetType,
    required this.totalPackets,
    required this.gridSize,
    required this.bitsPerChannel,
    required this.payload,
    this.checksum = 0,
  });

  final int protocolVersion;
  final String sessionId;
  final int frameId;
  final int packetId;
  final int packetType;
  final int totalPackets;
  final int gridSize;
  final int bitsPerChannel;
  final Uint8List payload;
  final int checksum;
}

class PlosFrameDto {
  const PlosFrameDto({
    required this.protocolVersion,
    required this.sessionId,
    required this.streamId,
    required this.frameId,
    required this.packetId,
    required this.packetType,
    required this.totalPackets,
    required this.syncMarker,
    required this.timestamp,
    required this.gridSize,
    required this.bitsPerCell,
    required this.payload,
    this.checksum = 0,
  });

  final int protocolVersion;
  final String sessionId;
  final int streamId;
  final int frameId;
  final int packetId;
  final int packetType;
  final int totalPackets;
  final int syncMarker;
  final int timestamp;
  final int gridSize;
  final int bitsPerCell;
  final Uint8List payload;
  final int checksum;
}

class DataChunkDto {
  const DataChunkDto({
    required this.sessionId,
    required this.chunkId,
    required this.totalChunks,
    required this.payload,
  });

  final String sessionId;
  final int chunkId;
  final int totalChunks;
  final Uint8List payload;
}

class CompressionOutputDto {
  const CompressionOutputDto({
    required this.originalSize,
    required this.outputSize,
    required this.bytes,
  });

  final int originalSize;
  final int outputSize;
  final Uint8List bytes;
}

class QualityScoreInputDto {
  const QualityScoreInputDto({
    required this.framesReceived,
    required this.framesCorrupted,
    required this.framesLost,
    required this.missingPacketCount,
    required this.framesRetried,
    required this.detectionAccuracy,
    required this.avgBrightness,
    required this.detectionSuccessRate,
    this.fecParityGenerated = 0,
    this.fecRecoverySuccessRate = 0,
    this.fecParityEfficiency = 0,
    this.fecOverhead = 0,
  });

  final int framesReceived;
  final int framesCorrupted;
  final int framesLost;
  final int missingPacketCount;
  final int framesRetried;
  final double detectionAccuracy;
  final double avgBrightness;
  final double detectionSuccessRate;
  final int fecParityGenerated;
  final double fecRecoverySuccessRate;
  final double fecParityEfficiency;
  final double fecOverhead;
}

class QualityScoreOutputDto {
  const QualityScoreOutputDto({
    required this.score,
    required this.frameLossFactor,
    required this.decodeErrorFactor,
    required this.retryFactor,
    required this.detectionStabilityFactor,
    required this.brightnessFactor,
    required this.recoveryFactor,
  });

  final double score;
  final double frameLossFactor;
  final double decodeErrorFactor;
  final double retryFactor;
  final double detectionStabilityFactor;
  final double brightnessFactor;
  final double recoveryFactor;
}
