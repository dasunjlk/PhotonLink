import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/compression_type.dart';
import 'package:photonlink_app/protocols/interfaces/encryption_mode.dart';
import 'package:photonlink_app/transfer/core/payload_pipeline.dart';
import 'package:photonlink_app/transfer/security/encryption_key_provider.dart';
import 'package:photonlink_app/transfer/security/session_key_exchange.dart';

void main() {
  final pipeline = PayloadPipeline();
  final keyProvider = EncryptionKeyProvider();

  test('integrity after compression only', () async {
    final file = Uint8List.fromList(List.generate(400, (i) => i % 256));
    final prepared = await pipeline.prepareForSend(
      fileBytes: file,
      compression: CompressionType.gzip,
      encryption: EncryptionMode.disabled,
      keyProvider: keyProvider,
    );
    final restored = await pipeline.restorePlaintext(
      wireBytes: prepared.wireBytes,
      meta: MetadataPacketFields(
        compression: CompressionType.gzip,
        encryption: EncryptionMode.disabled,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
      ),
      keyProvider: keyProvider,
    );
    expect(restored, file);
  });

  test('integrity after compression and encryption', () async {
    final file = Uint8List.fromList(List.generate(300, (i) => (i * 3) % 256));
    final kx = await SessionKeyExchange().generateForSender();
    keyProvider.setSessionKey(kx.sessionKey);
    final prepared = await pipeline.prepareForSend(
      fileBytes: file,
      compression: CompressionType.gzip,
      encryption: EncryptionMode.enabled,
      keyProvider: keyProvider,
    );
    final restored = await pipeline.restorePlaintext(
      wireBytes: prepared.wireBytes,
      meta: MetadataPacketFields(
        compression: CompressionType.gzip,
        encryption: EncryptionMode.enabled,
        originalSize: prepared.originalSize,
        originalSha256: prepared.originalSha256,
      ),
      keyProvider: keyProvider,
    );
    expect(restored, file);
  });
}
