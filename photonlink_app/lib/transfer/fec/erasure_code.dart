import 'dart:typed_data';

/// Transport-independent erasure coding interface.
///
/// Implementations: [ReedSolomonCodec] (Phase 7).
/// Future: LT Codes, Raptor, RaptorQ (Phase 8+).
abstract interface class ErasureCode {
  /// Encodes [dataSymbols] into [parityCount] parity symbols of [symbolLength].
  List<Uint8List> encodeBlock({
    required List<Uint8List> dataSymbols,
    required int parityCount,
    required int symbolLength,
  });

  /// Recovers missing data symbols from available data and parity.
  ///
  /// [erasures] lists indices (0..dataCount+parityCount-1) that are missing.
  /// [available] maps index -> symbol bytes for received symbols.
  List<Uint8List>? decodeBlock({
    required int dataCount,
    required int parityCount,
    required int symbolLength,
    required List<int> erasures,
    required Map<int, Uint8List> available,
  });
}
