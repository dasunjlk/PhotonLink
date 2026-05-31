import 'dart:typed_data';

/// Computes and validates checksums for data integrity.
abstract interface class ChecksumValidator {
  int compute(Uint8List data);
  bool validate(Uint8List data, int expected);
}
