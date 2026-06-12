import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/security/safe_filename.dart';

void main() {
  test('rejects path traversal sequences', () {
    expect(safeTransferFilename('../etc/passwd'), 'passwd');
    expect(safeTransferFilename('..'), 'received_file');
    expect(safeTransferFilename('folder/../../secret.txt'), 'secret.txt');
  });

  test('sanitizes unsafe characters', () {
    expect(safeTransferFilename('my file (1).txt'), 'my_file__1_.txt');
  });
}
