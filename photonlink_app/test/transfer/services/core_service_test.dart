import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/services/core/impl/dart_core_service.dart';
import 'package:photonlink_app/transfer/core/chunking_engine.dart';

/// Golden vectors for Rust cross-validation (Phase 8).
/// Run `cargo test` in photonlink_core/ to verify byte-exact parity.
void main() {
  group('Phase 8 golden vectors', () {
    test('SHA-256 empty and hello', () {
      const core = DartCoreService();
      expect(
        core.sha256Hex(Uint8List(0)),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        core.sha256Hex(Uint8List.fromList('hello'.codeUnits)),
        '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      );
    });

    test('CRC32 empty and hello', () {
      const core = DartCoreService();
      expect(core.crc32Compute(Uint8List(0)), 0);
      expect(
        core.crc32Compute(Uint8List.fromList('hello'.codeUnits)),
        0x3610A686,
      );
    });

    test('chunking 1200 bytes at 512', () {
      const engine = ChunkingEngine();
      final data = Uint8List.fromList(List.generate(1200, (i) => i % 256));
      final chunks = engine.split(data: data, sessionId: 'gv', chunkSize: 512);
      expect(chunks.length, 3);
      expect(chunks[0].payload.length, 512);
      expect(chunks[2].payload.length, 176);
      final merged = engine.merge(chunks);
      expect(merged, data);
    });
  });
}
