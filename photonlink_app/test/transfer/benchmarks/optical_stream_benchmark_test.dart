import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';
import 'package:photonlink_app/transfer/optical_stream/optical_stream_codec.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  test('Optical Stream benchmark: encode throughput vs QR and Color Matrix', () {
    final osCodec = OpticalStreamFrameCodec(gridSize: 48, bitsPerCell: 3);
    final cmCodec = ColorMatrixFrameCodec(gridSize: 24, bitsPerChannel: 2);
    const qrCodec = QrFrameCodec();

    final data = DataPacket(
      sessionId: 'bench-session',
      chunkId: 0,
      totalChunks: 100,
      payload: Uint8List.fromList(List.generate(256, (i) => i % 256)),
    );

    Future<int> benchEncode(dynamic codec, int iterations) async {
      final sw = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        if (codec is OpticalStreamFrameCodec) {
          codec.encodeFrame(data);
        } else if (codec is ColorMatrixFrameCodec) {
          codec.encodeFrame(data);
        } else if (codec is QrFrameCodec) {
          codec.encodeFrame(data);
        }
      }
      sw.stop();
      return sw.elapsedMilliseconds;
    }

    const iterations = 50;

    // ignore: avoid_print
    print('Optical Stream benchmark ($iterations iterations):');

    // Run synchronously in test
    final osSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      osCodec.encodeFrame(data);
    }
    osSw.stop();

    final cmSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      cmCodec.encodeFrame(data);
    }
    cmSw.stop();

    final qrSw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      qrCodec.encodeFrame(data);
    }
    qrSw.stop();

    // ignore: avoid_print
    print('  Optical Stream: ${osSw.elapsedMilliseconds}ms');
    // ignore: avoid_print
    print('  Color Matrix:   ${cmSw.elapsedMilliseconds}ms');
    // ignore: avoid_print
    print('  QR:             ${qrSw.elapsedMilliseconds}ms');

    expect(osSw.elapsedMilliseconds, lessThan(30000));
    expect(cmSw.elapsedMilliseconds, lessThan(30000));
    expect(qrSw.elapsedMilliseconds, lessThan(30000));
  });
}
