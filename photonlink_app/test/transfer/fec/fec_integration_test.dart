import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/reliability/transfer_diagnostics.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/adaptive/fec_adaptation_policy.dart';
import 'package:photonlink_app/transfer/adaptive/models/environment_profile.dart';
import 'package:photonlink_app/transfer/adaptive/models/quality_score.dart';
import 'package:photonlink_app/transfer/adaptive/quality_score_calculator.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';
import 'package:photonlink_app/transfer/core/reconstruction_engine.dart';
import 'package:photonlink_app/transfer/fec/fec_encoder.dart';
import 'package:photonlink_app/transfer/fec/models/fec_configuration.dart';
import 'package:photonlink_app/transfer/fec/models/fec_profile.dart';
import 'package:photonlink_app/transfer/fec/models/fec_statistics.dart';
import 'package:photonlink_app/transfer/fec/recovery_engine.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  group('RecoveryEngine', () {
    test('attemptRecovery injects recovered packets', () {
      const config = FecConfiguration(
        enabled: true,
        profile: FecProfile.balanced,
        redundancyPercent: 20,
        blockSize: 5,
      );
      const sessionId = 'sess-1';
      final data = List.generate(
        8,
        (i) => DataPacket(
          sessionId: sessionId,
          chunkId: i,
          totalChunks: 8,
          payload: Uint8List.fromList([i, i + 1, i + 2, i + 3]),
        ),
      );

      final engine = RecoveryEngine();
      engine.configure(config);
      final parity = engine.generateParity(
        dataPackets: data,
        sessionId: sessionId,
        totalChunks: 8,
      );
      expect(parity, isNotEmpty);

      final recon = ReconstructionEngine();
      recon.ingest(
        MetadataPacket(
          sessionId: sessionId,
          fileName: 't.bin',
          fileSize: 32,
          totalChunks: 8,
          sha256: 'abc',
          mimeType: 'application/octet-stream',
        ),
      );

      for (final p in data) {
        if (p.chunkId != 3) recon.ingest(p);
      }
      for (final p in parity) {
        engine.ingestParity(p);
      }

      final result = engine.attemptRecovery(recon);
      expect(result.success, isTrue);
      expect(recon.receivedChunkIds.contains(3), isTrue);
    });
  });

  group('QrFrameCodec ParityPacket', () {
    test('round-trip parity packet', () {
      const codec = QrFrameCodec();
      final packet = ParityPacket(
        sessionId: 'pl-test',
        parityId: 0,
        blockIndex: 0,
        parityIndexInBlock: 0,
        dataCount: 5,
        parityCount: 1,
        dataSymbolLength: 16,
        totalParity: 1,
        totalChunks: 10,
        payload: Uint8List.fromList([1, 2, 3, 4]),
      );
      final frame = codec.encodeFrame(packet);
      expect(frame, contains('|P|'));
      final decoded = codec.decodeFrame(frame);
      expect(decoded, isA<ParityPacket>());
      expect((decoded as ParityPacket).parityId, 0);
      expect(decoded.payload, packet.payload);
    });
  });

  group('ColorMatrixFrameCodec ParityPacket', () {
    test('round-trip parity packet', () {
      final codec = ColorMatrixFrameCodec(gridSize: 32, bitsPerChannel: 2);
      final packet = ParityPacket(
        sessionId: 'pl-cm',
        parityId: 0,
        blockIndex: 0,
        parityIndexInBlock: 0,
        dataCount: 3,
        parityCount: 1,
        dataSymbolLength: 8,
        totalParity: 1,
        totalChunks: 6,
        payload: Uint8List.fromList([10, 20, 30, 40]),
      );
      final frame = codec.encodeFrame(packet);
      expect(frame.packetType, ColorMatrixPacketType.parity);
      final decoded = codec.decodeFrame(frame);
      expect(decoded, isA<ParityPacket>());
    });
  });

  group('FecAdaptationPolicy', () {
    test('increases redundancy on poor quality', () {
      const policy = FecAdaptationPolicy();
      const config = FecConfiguration(enabled: true);
      final rec = policy.evaluate(
        current: config,
        qualityScore: const QualityScore(score: 40),
        environment: const EnvironmentProfile(frameLossRate: 0.2),
      );
      expect(rec, FecRecommendation.increaseRedundancy);
    });
  });

  group('QualityScoreCalculator FEC', () {
    test('includes recovery factor when FEC stats present', () {
      const calc = QualityScoreCalculator();
      final without = calc.calculate(
        diagnostics: const FrameDiagnostics(),
        environment: const EnvironmentProfile(),
      );
      final withFec = calc.calculate(
        diagnostics: const FrameDiagnostics(),
        environment: const EnvironmentProfile(),
        fecStats: const FecStatistics(
          parityGenerated: 10,
          packetsRecovered: 5,
          recoveryAttempts: 1,
          recoverySuccessCount: 1,
        ),
      );
      expect(withFec.recoveryFactor, isNot(100.0));
      expect(without.recoveryFactor, 100.0);
    });
  });
}
