import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/qr/qr_frame_codec.dart';

void main() {
  const codec = QrFrameCodec();

  test('rejects metadata with invalid sha256', () {
    final frame =
        'PL2|M|sess|0|1|${'e' * 20}'; // not valid base64/json path
    expect(codec.decodeFrame(frame), isNull);
  });

  test('rejects oversized raw scan string', () {
    final huge = 'PL2|M|s|0|1|${'A' * 5000}';
    expect(codec.decodeFrame(huge), isNull);
  });
}
