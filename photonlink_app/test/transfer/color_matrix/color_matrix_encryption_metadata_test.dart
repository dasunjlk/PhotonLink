import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/core/constants.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/color_matrix/color_matrix_frame_codec.dart';

void main() {
  test('metadata roundtrip embeds and extracts keyExchangePayload', () {
    final codec = ColorMatrixFrameCodec(gridSize: 24);
    codec.encoderKeyExchangePayload = 'dGVzdC1rZXktYmFzZTY0LXN0cmluZw==';

    const shaWire =
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    const shaOrig =
        '2c26b46b68ffc68ff99b453c1d3041340e08aa502aecc896426aa675e85b978';

    final metadata = MetadataPacket(
      sessionId: 'cm-1',
      fileName: 's.bin',
      fileSize: 128,
      totalChunks: 2,
      sha256: shaWire,
      mimeType: 'application/octet-stream',
      protocolVersion: AppConstants.protocolVersion,
      compression: CompressionType.gzip,
      encryption: EncryptionMode.enabled,
      originalSize: 256,
      originalSha256: shaOrig,
    );

    final frame = codec.encodeFrame(metadata);
    final decoded = codec.decodeFrame(frame);

    expect(decoded, isA<MetadataPacket>());
    final meta = decoded! as MetadataPacket;
    expect(meta.encryption, EncryptionMode.enabled);
    expect(meta.compression, CompressionType.gzip);
    expect(codec.lastDecodedKeyExchange, codec.encoderKeyExchangePayload);

    final jsonStr = utf8.decode(frame.payload);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    expect(map['encryption'], 'enabled');
    expect(map['compression'], 'gzip');
    expect(map['keyExchangePayload'], codec.encoderKeyExchangePayload);
  });
}
