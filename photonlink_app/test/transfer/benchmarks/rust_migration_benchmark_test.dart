import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/services/core/core_backend.dart';
import 'package:photonlink_app/services/core/impl/dart_compression_service.dart';
import 'package:photonlink_app/services/core/impl/dart_core_service.dart';
import 'package:photonlink_app/services/core/impl/dart_encryption_service.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';
import 'package:photonlink_app/transfer/core/reconstruction_engine.dart';
import 'package:photonlink_app/transfer/fec/fec_encoder.dart';
import 'package:photonlink_app/transfer/fec/models/fec_configuration.dart';
import 'package:photonlink_app/transfer/fec/recovery_engine.dart';
import 'package:photonlink_app/transfer/security/session_key_exchange.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';

/// Phase 8 migration benchmarks — measures Dart backend performance.
/// Rust columns to be filled after `cargo build --release` + FRB codegen.
void main() {
  const backend = CoreBackend.dart;
  final core = const DartCoreService();
  final compression = DartCompressionService();
  final encryption = DartEncryptionService();
  const chunking = ChunkingEngine();
  const iterations = 100;

  test('Phase 8 migration benchmark report', () async {
    final buffer = StringBuffer('=== PhotonLink Phase 8 Migration Benchmarks ===\n');
    buffer.writeln('Backend: ${backend.name}');
    buffer.writeln('Iterations: $iterations');
    buffer.writeln('');

    // ── Chunking ──
    final chunkData = Uint8List.fromList(List.generate(65536, (i) => i % 256));
    final chunkSw = Stopwatch()..start();
    List<DataPacket>? chunks;
    for (var i = 0; i < iterations; i++) {
      chunks = chunking.split(data: chunkData, sessionId: 'bench');
    }
    chunkSw.stop();
    buffer.writeln(
      'Chunking 64KB x$iterations: ${chunkSw.elapsedMicroseconds} µs '
      '(${chunks!.length} chunks)',
    );

    // ── Reconstruction ──
    final recon = ReconstructionEngine();
    recon.ingest(MetadataPacket(
      sessionId: 'bench',
      fileName: 'f.bin',
      fileSize: chunkData.length,
      totalChunks: chunks.length,
      sha256: 'a' * 64,
      mimeType: 'application/octet-stream',
      protocolVersion: 3,
    ));
    for (final c in chunks) {
      recon.ingest(c);
    }
    final reconSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      recon.rebuild();
    }
    reconSw.stop();
    buffer.writeln(
      'Reconstruction rebuild x$iterations: ${reconSw.elapsedMicroseconds} µs',
    );

    // ── SHA-256 ──
    final hashSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      core.sha256Hex(chunkData);
    }
    hashSw.stop();
    buffer.writeln('SHA-256 64KB x$iterations: ${hashSw.elapsedMicroseconds} µs');

    // ── CRC32 ──
    final crcSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      core.crc32Compute(chunkData);
    }
    crcSw.stop();
    buffer.writeln('CRC32 64KB x$iterations: ${crcSw.elapsedMicroseconds} µs');

    // ── Compression ──
    final compSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      compression.compress(chunkData, CompressionType.gzip);
    }
    compSw.stop();
    buffer.writeln('GZip 64KB x$iterations: ${compSw.elapsedMicroseconds} µs');

    // ── Encryption ──
    final kx = await SessionKeyExchange().generateForSender();
    final encSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      await encryption.encryptIfEnabled(
        plaintext: chunkData,
        sessionKey: kx.sessionKey,
        mode: EncryptionMode.enabled,
      );
    }
    encSw.stop();
    buffer.writeln(
      'ChaCha20-Poly1305 64KB x$iterations: ${encSw.elapsedMicroseconds} µs',
    );

    // ── FEC encode ──
    const fecConfig = FecConfiguration(enabled: true);
    const fecSessionId = 'bench-fec';
    const fecChunkCount = 10;
    final fecData = List.generate(
      fecChunkCount,
      (i) => DataPacket(
        sessionId: fecSessionId,
        chunkId: i,
        totalChunks: fecChunkCount,
        payload: Uint8List(256),
      ),
    );
    final fecEncoder = FecEncoder();
    final fecSw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      fecEncoder.encode(
        dataPackets: fecData,
        config: fecConfig,
        sessionId: fecSessionId,
        totalChunks: fecChunkCount,
      );
    }
    fecSw.stop();
    buffer.writeln('FEC encode 10 chunks x50: ${fecSw.elapsedMicroseconds} µs');

    // ── FEC recovery ──
    final recovery = RecoveryEngine();
    recovery.configure(fecConfig);
    final parity = fecEncoder.encode(
      dataPackets: fecData,
      config: fecConfig,
      sessionId: fecSessionId,
      totalChunks: fecChunkCount,
    );
    for (final p in parity) {
      recovery.ingestParity(p);
    }
    final recon2 = ReconstructionEngine();
    recon2.ingest(MetadataPacket(
      sessionId: fecSessionId,
      fileName: 'f.bin',
      fileSize: 1000,
      totalChunks: fecChunkCount,
      sha256: 'a' * 64,
      mimeType: 'application/octet-stream',
      protocolVersion: 3,
    ));
    for (var i = 0; i < fecChunkCount - 1; i++) {
      recon2.ingest(fecData[i]);
    }
    final fecRecSw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      recovery.attemptRecovery(recon2);
    }
    fecRecSw.stop();
    buffer.writeln('FEC recovery x50: ${fecRecSw.elapsedMicroseconds} µs');

    buffer.writeln('');
    buffer.writeln('Rust comparison: run `cargo test --release` in photonlink_core/');
    buffer.writeln('after installing Rust toolchain, then re-run with backend=rust.');

    // ignore: avoid_print
    print(buffer.toString());
  });
}
