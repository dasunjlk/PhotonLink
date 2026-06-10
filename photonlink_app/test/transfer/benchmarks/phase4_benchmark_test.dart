import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/compression/compression_manager.dart';
import 'package:photonlink_app/transfer/encryption/chacha20_encryption_strategy.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';
import 'package:photonlink_app/transfer/serialization/packet_id_ranges.dart';

/// Captures Phase 4 microbenchmark results (printed in test output).
void main() {
  test('phase 4 benchmark report', () async {
    final data = List<int>.generate(32 * 1024, (i) => i % 256);
    final cm = CompressionManager();

    final swGzip = Stopwatch()..start();
    final gz = cm.compress(data, CompressionType.gzip);
    swGzip.stop();

    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final enc = ChaCha20EncryptionStrategy();
    final swEnc = Stopwatch()..start();
    await enc.encrypt(Uint8List.fromList(gz.bytes), key);
    swEnc.stop();

    final ids = List.generate(500, (i) => i);
    final rangeLen = utf8.encode(PacketIdRanges.encode(ids)).length;
    final jsonLen = utf8.encode(PacketIdRanges.encodeJsonArray(ids)).length;

    const codec = QrFrameCodec();
    final swQr = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      codec.encodeFrame(
        DataPacket(
          sessionId: 'bench',
          chunkId: i % 10,
          totalChunks: 10,
          payload: Uint8List.fromList(data.sublist(0, 200)),
        ),
      );
    }
    swQr.stop();

    // ignore: avoid_print
    print('''
=== PhotonLink Phase 4 Benchmarks ===
GZip 32KB: ${swGzip.elapsedMicroseconds} µs, ratio ${(gz.outputSize / data.length).toStringAsFixed(2)}
ChaCha20-Poly1305 32KB: ${swEnc.elapsedMicroseconds} µs
ACK id list 500: range $rangeLen B vs json $jsonLen B (${((1 - rangeLen / jsonLen) * 100).toStringAsFixed(0)}% smaller)
QR encode 100 frames: ${swQr.elapsedMicroseconds} µs total
''');

    expect(rangeLen, lessThan(jsonLen));
  });
}
