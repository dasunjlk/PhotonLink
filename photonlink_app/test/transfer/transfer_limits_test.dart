import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/core/transfer_limits.dart';

void main() {
  test('QR file size capped at 512 KB', () {
    expect(
      () => TransferLimits.validateFileSize(TransferLimits.maxQrFileBytes + 1),
      throwsA(isA<TransferLimitException>()),
    );
    expect(
      () => TransferLimits.validateFileSize(TransferLimits.maxQrFileBytes),
      returnsNormally,
    );
  });

  test('Color Matrix file size allows up to 2 MB', () {
    expect(
      () => TransferLimits.validateColorMatrixFileSize(
        TransferLimits.maxColorMatrixFileBytes + 1,
      ),
      throwsA(isA<TransferLimitException>()),
    );
    expect(
      () => TransferLimits.validateColorMatrixFileSize(600 * 1024),
      returnsNormally,
    );
    expect(
      () => TransferLimits.validateFileSize(600 * 1024),
      throwsA(isA<TransferLimitException>()),
    );
  });

  test('metadata validation respects maxBytes', () {
    expect(
      () => TransferLimits.validateMetadata(
        fileName: 'f.bin',
        fileSize: TransferLimits.maxColorMatrixFileBytes,
        totalChunks: 1,
        sha256: 'a' * 64,
        maxBytes: TransferLimits.maxColorMatrixFileBytes,
      ),
      returnsNormally,
    );
    expect(
      () => TransferLimits.validateMetadata(
        fileName: 'f.bin',
        fileSize: TransferLimits.maxQrFileBytes + 1,
        totalChunks: 1,
        sha256: 'a' * 64,
        maxBytes: TransferLimits.maxQrFileBytes,
      ),
      throwsA(isA<TransferLimitException>()),
    );
  });
}
