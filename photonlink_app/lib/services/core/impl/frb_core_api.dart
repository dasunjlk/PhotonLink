import 'dart:typed_data';

import '../../../src/rust/api.dart' as rust;
import '../../../src/rust/diagnostics.dart' as rust_diag;
import '../photon_link_core_api.dart' as app;

/// Live [app.PhotonLinkCoreApi] backed by generated flutter_rust_bridge bindings.
class FrbCoreApi implements app.PhotonLinkCoreApi {
  const FrbCoreApi();

  @override
  Future<String> coreVersion() async => rust.coreVersion();

  @override
  String sha256Hex(Uint8List data) => rust.sha256Hex(data: data);

  @override
  bool sha256Verify(Uint8List data, String expected) =>
      rust.sha256Verify(data: data, expected: expected);

  @override
  int crc32Compute(Uint8List data) => rust.crc32Compute(data: data);

  @override
  bool crc32Validate(Uint8List data, int expected) =>
      rust.crc32Validate(data: data, expected: expected);

  @override
  String encodePl2DataFrame({
    required String sessionId,
    required int chunkId,
    required int totalChunks,
    required Uint8List payload,
  }) =>
      rust.encodePl2DataFrame(
        sessionId: sessionId,
        chunkId: chunkId,
        totalChunks: totalChunks,
        payload: payload,
      );

  @override
  app.Pl2FrameDto decodePl2Frame(String raw) {
    final frame = rust.decodePl2Frame(raw: raw);
    return app.Pl2FrameDto(
      packetType: frame.packetType,
      sessionId: frame.sessionId,
      seq: frame.seq,
      total: frame.total,
      payload: frame.payload,
    );
  }

  @override
  Uint8List encodePlcmFrame(app.PlcmFrameDto frame) =>
      rust.encodePlcmFrame(frame: _toRustPlcm(frame));

  @override
  app.PlcmFrameDto decodePlcmFrame(Uint8List bytes) {
    final frame = rust.decodePlcmFrame(bytes: bytes);
    return app.PlcmFrameDto(
      protocolVersion: frame.protocolVersion,
      sessionId: frame.sessionId,
      frameId: frame.frameId,
      packetId: frame.packetId,
      packetType: frame.packetType,
      totalPackets: frame.totalPackets,
      gridSize: frame.gridSize,
      bitsPerChannel: frame.bitsPerChannel,
      payload: frame.payload,
      checksum: frame.checksum,
    );
  }

  @override
  Uint8List encodePlosFrame(app.PlosFrameDto frame) =>
      rust.encodePlosFrame(frame: _toRustPlos(frame));

  @override
  app.PlosFrameDto decodePlosFrame(Uint8List bytes) {
    final frame = rust.decodePlosFrame(bytes: bytes);
    return app.PlosFrameDto(
      protocolVersion: frame.protocolVersion,
      sessionId: frame.sessionId,
      streamId: frame.streamId,
      frameId: frame.frameId,
      packetId: frame.packetId,
      packetType: frame.packetType,
      totalPackets: frame.totalPackets,
      syncMarker: frame.syncMarker,
      timestamp: frame.timestamp.toInt(),
      gridSize: frame.gridSize,
      bitsPerCell: frame.bitsPerCell,
      payload: frame.payload,
      checksum: frame.checksum,
    );
  }

  @override
  List<app.DataChunkDto> chunkSplit({
    required Uint8List data,
    required String sessionId,
    int chunkSize = 512,
  }) =>
      rust
          .chunkSplit(data: data, sessionId: sessionId, chunkSize: chunkSize)
          .map(
            (chunk) => app.DataChunkDto(
              sessionId: chunk.sessionId,
              chunkId: chunk.chunkId,
              totalChunks: chunk.totalChunks,
              payload: chunk.payload,
            ),
          )
          .toList(growable: false);

  @override
  Uint8List chunkMerge(List<app.DataChunkDto> chunks) => rust.chunkMerge(
        chunks: chunks
            .map(
              (chunk) => rust.DataChunkDto(
                sessionId: chunk.sessionId,
                chunkId: chunk.chunkId,
                totalChunks: chunk.totalChunks,
                payload: chunk.payload,
              ),
            )
            .toList(growable: false),
      );

  @override
  app.CompressionOutputDto compressData(Uint8List input, String kind) {
    final result = rust.compressData(input: input, kind: kind);
    return _fromRustCompression(result);
  }

  @override
  app.CompressionOutputDto decompressData(
    Uint8List input, {
    required String kind,
    required int originalSize,
  }) {
    final result = rust.decompressData(
      input: input,
      kind: kind,
      originalSize: originalSize,
    );
    return _fromRustCompression(result);
  }

  @override
  Uint8List encryptData(Uint8List plaintext, Uint8List sessionKey) =>
      rust.encryptData(plaintext: plaintext, sessionKey: sessionKey);

  @override
  Uint8List decryptData(Uint8List wire, Uint8List sessionKey) =>
      rust.decryptData(wire: wire, sessionKey: sessionKey);

  @override
  app.QualityScoreOutputDto calculateQualityScore(
    app.QualityScoreInputDto input,
  ) {
    final result = rust.calculateQualityScore(
      input: rust_diag.QualityScoreInput(
        framesReceived: input.framesReceived,
        framesCorrupted: input.framesCorrupted,
        framesLost: input.framesLost,
        missingPacketCount: input.missingPacketCount,
        framesRetried: input.framesRetried,
        detectionAccuracy: input.detectionAccuracy,
        avgBrightness: input.avgBrightness,
        detectionSuccessRate: input.detectionSuccessRate,
        fecParityGenerated: input.fecParityGenerated,
        fecRecoverySuccessRate: input.fecRecoverySuccessRate,
        fecParityEfficiency: input.fecParityEfficiency,
        fecOverhead: input.fecOverhead,
      ),
    );
    return app.QualityScoreOutputDto(
      score: result.score,
      frameLossFactor: result.frameLossFactor,
      decodeErrorFactor: result.decodeErrorFactor,
      retryFactor: result.retryFactor,
      detectionStabilityFactor: result.detectionStabilityFactor,
      brightnessFactor: result.brightnessFactor,
      recoveryFactor: result.recoveryFactor,
    );
  }

  @override
  List<Uint8List> fecEncodeBlock({
    required List<Uint8List> dataSymbols,
    required int parityCount,
    required int symbolLength,
  }) =>
      rust.fecEncodeBlock(
        dataSymbols: dataSymbols,
        parityCount: parityCount,
        symbolLength: symbolLength,
      );

  @override
  List<Uint8List>? fecDecodeBlock({
    required int dataCount,
    required int parityCount,
    required int symbolLength,
    required List<int> erasures,
    required Map<int, Uint8List> available,
  }) {
    final keys = available.keys.toList(growable: false);
    final values = keys.map((key) => available[key]!).toList(growable: false);
    return rust.fecDecodeBlock(
      dataCount: dataCount,
      parityCount: parityCount,
      symbolLength: symbolLength,
      erasures: erasures,
      availableKeys: keys,
      availableValues: values,
    );
  }

  rust.PlcmFrameDto _toRustPlcm(app.PlcmFrameDto frame) => rust.PlcmFrameDto(
        protocolVersion: frame.protocolVersion,
        sessionId: frame.sessionId,
        frameId: frame.frameId,
        packetId: frame.packetId,
        packetType: frame.packetType,
        totalPackets: frame.totalPackets,
        gridSize: frame.gridSize,
        bitsPerChannel: frame.bitsPerChannel,
        payload: frame.payload,
        checksum: frame.checksum,
      );

  rust.PlosFrameDto _toRustPlos(app.PlosFrameDto frame) => rust.PlosFrameDto(
        protocolVersion: frame.protocolVersion,
        sessionId: frame.sessionId,
        streamId: frame.streamId,
        frameId: frame.frameId,
        packetId: frame.packetId,
        packetType: frame.packetType,
        totalPackets: frame.totalPackets,
        syncMarker: frame.syncMarker,
        timestamp: BigInt.from(frame.timestamp),
        gridSize: frame.gridSize,
        bitsPerCell: frame.bitsPerCell,
        payload: frame.payload,
        checksum: frame.checksum,
      );

  app.CompressionOutputDto _fromRustCompression(rust.CompressionOutputDto result) =>
      app.CompressionOutputDto(
        originalSize: result.originalSize,
        outputSize: result.outputSize,
        bytes: result.bytes,
      );
}
