import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/fec/fec_encoder.dart';
import 'package:photonlink_app/transfer/fec/models/fec_configuration.dart';
import 'package:photonlink_app/transfer/fec/models/fec_profile.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';

void main() {
  test('FEC benchmark: encode and recovery overhead', () {
    const config = FecConfiguration(
      enabled: true,
      profile: FecProfile.balanced,
      redundancyPercent: 10,
      blockSize: 10,
    );
    const sessionId = 'bench';
    const chunkCount = 100;
    const payloadSize = 256;

    final data = List.generate(
      chunkCount,
      (i) => DataPacket(
        sessionId: sessionId,
        chunkId: i,
        totalChunks: chunkCount,
        payload: Uint8List(payloadSize),
      ),
    );

    final sw = Stopwatch()..start();
    final encoder = FecEncoder();
    final parity = encoder.encode(
      dataPackets: data,
      config: config,
      sessionId: sessionId,
      totalChunks: chunkCount,
    );
    sw.stop();

    final overhead = parity.length / chunkCount;
    expect(overhead, greaterThan(0));
    expect(sw.elapsedMilliseconds, lessThan(5000));

    // ignore: avoid_print
    print(
      'FEC benchmark: ${chunkCount} chunks, ${parity.length} parity, '
      '${sw.elapsedMilliseconds}ms, overhead ${overhead.toStringAsFixed(2)}',
    );
  });
}
