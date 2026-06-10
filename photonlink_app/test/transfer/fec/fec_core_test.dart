import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/fec/fec_block_planner.dart';
import 'package:photonlink_app/transfer/fec/fec_decoder.dart';
import 'package:photonlink_app/transfer/fec/fec_encoder.dart';
import 'package:photonlink_app/transfer/fec/models/fec_configuration.dart';
import 'package:photonlink_app/transfer/fec/models/fec_profile.dart';
import 'package:photonlink_app/transfer/fec/reedsolomon/galois_field.dart';
import 'package:photonlink_app/transfer/fec/reedsolomon/reed_solomon_codec.dart';

List<DataPacket> _makeDataPackets({
  required String sessionId,
  required int count,
  int payloadSize = 16,
}) {
  return List.generate(
    count,
    (i) => DataPacket(
      sessionId: sessionId,
      chunkId: i,
      totalChunks: count,
      payload: Uint8List.fromList(
        List.generate(payloadSize, (b) => (i * 17 + b) & 0xFF),
      ),
    ),
  );
}

void main() {
  group('GaloisField', () {
    test('add/sub are XOR', () {
      expect(GaloisField.add(0xAB, 0xCD), 0xAB ^ 0xCD);
      expect(GaloisField.sub(0xAB, 0xCD), GaloisField.add(0xAB, 0xCD));
    });

    test('mul and div are inverses for non-zero', () {
      expect(GaloisField.div(GaloisField.mul(7, 13), 13), 7);
    });
  });

  group('ReedSolomonCodec', () {
    const codec = ReedSolomonCodec();

    test('encode/decode round-trip with no loss', () {
      const k = 4;
      const m = 2;
      const len = 32;
      final data = List.generate(
        k,
        (i) => Uint8List.fromList(List.generate(len, (b) => i + b)),
      );
      final parity = codec.encodeBlock(
        dataSymbols: data,
        parityCount: m,
        symbolLength: len,
      );
      expect(parity.length, m);

      final available = <int, Uint8List>{};
      for (var i = 0; i < k; i++) {
        available[i] = data[i];
      }
      for (var i = 0; i < m; i++) {
        available[k + i] = parity[i];
      }

      final recovered = codec.decodeBlock(
        dataCount: k,
        parityCount: m,
        symbolLength: len,
        erasures: [],
        available: available,
      );
      expect(recovered, isNotNull);
      for (var i = 0; i < k; i++) {
        expect(recovered![i], data[i]);
      }
    });

    test('recovers single erasure', () {
      const k = 5;
      const m = 2;
      const len = 8;
      final data = List.generate(
        k,
        (i) => Uint8List.fromList(List.generate(len, (b) => (i << 4) | b)),
      );
      final parity = codec.encodeBlock(
        dataSymbols: data,
        parityCount: m,
        symbolLength: len,
      );

      final available = <int, Uint8List>{};
      for (var i = 0; i < k; i++) {
        if (i != 2) available[i] = data[i];
      }
      for (var i = 0; i < m; i++) {
        available[k + i] = parity[i];
      }

      final recovered = codec.decodeBlock(
        dataCount: k,
        parityCount: m,
        symbolLength: len,
        erasures: [2],
        available: available,
      );
      expect(recovered, isNotNull);
      expect(recovered![2], data[2]);
    });
  });

  group('FecEncoder/Decoder', () {
    test('generates parity and recovers missing packets', () {
      const config = FecConfiguration(
        enabled: true,
        profile: FecProfile.balanced,
        redundancyPercent: 20,
        blockSize: 5,
      );
      const sessionId = 'test-session';
      final data = _makeDataPackets(sessionId: sessionId, count: 10);
      final encoder = FecEncoder();
      final parity = encoder.encode(
        dataPackets: data,
        config: config,
        sessionId: sessionId,
        totalChunks: 10,
      );
      expect(parity, isNotEmpty);

      final received = <int, DataPacket>{};
      final missing = <int>{2, 7};
      for (final p in data) {
        if (!missing.contains(p.chunkId)) {
          received[p.chunkId] = p;
        }
      }
      final parityMap = {for (final p in parity) p.parityId: p};

      final decoder = FecDecoder();
      final result = decoder.recover(
        config: config,
        sessionId: sessionId,
        totalChunks: 10,
        receivedData: received,
        receivedParity: parityMap,
        missingChunkIds: missing,
      );

      expect(result.success, isTrue);
      expect(result.recoveredCount, greaterThan(0));
      expect(result.recovered.containsKey(2) || result.recovered.containsKey(7),
          isTrue);
    });

    test('redundancy calculation per profile', () {
      const config = FecConfiguration(
        enabled: true,
        profile: FecProfile.highProtection,
        redundancyPercent: 20,
        blockSize: 10,
      );
      expect(config.parityCountForBlock(10), 2);
      expect(config.totalParityCount(25), greaterThan(0));
    });
  });

  group('FecBlockPlanner', () {
    test('plans blocks from total chunks', () {
      const planner = FecBlockPlanner();
      const config = FecConfiguration(
        enabled: true,
        profile: FecProfile.balanced,
        blockSize: 10,
      );
      final plans = planner.planFromTotal(totalChunks: 25, config: config);
      expect(plans.length, 3);
      expect(plans.first.dataCount, 10);
      expect(plans.last.dataCount, 5);
    });
  });
}
