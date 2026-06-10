import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/core/integrity_verifier.dart';

void main() {
  const verifier = IntegrityVerifier();

  test('SHA-256 verify passes for intact data', () {
    final data = Uint8List.fromList([10, 20, 30, 40]);
    final hash = verifier.compute(data);
    expect(verifier.verify(data, hash), isTrue);
  });

  test('SHA-256 verify fails for mutated data', () {
    final data = Uint8List.fromList([10, 20, 30, 40]);
    final hash = verifier.compute(data);
    final mutated = Uint8List.fromList([10, 20, 30, 41]);
    expect(verifier.verify(mutated, hash), isFalse);
  });

  test('supported extensions check', () {
    expect(isSupportedExtension('txt'), isTrue);
    expect(isSupportedExtension('pdf'), isTrue);
    expect(isSupportedExtension('mp4'), isFalse);
  });
}
