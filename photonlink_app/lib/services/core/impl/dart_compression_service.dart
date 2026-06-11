import 'dart:typed_data';

import '../../../protocols/interfaces/compression_type.dart';
import '../../../transfer/compression/compression_manager.dart';
import '../../../transfer/compression/models/compression_result.dart';
import '../compression_service.dart';
import '../photon_link_core_api.dart';

/// Dart backend — delegates to [CompressionManager].
class DartCompressionService implements CompressionService {
  DartCompressionService({CompressionManager? manager})
      : _manager = manager ?? CompressionManager();

  final CompressionManager _manager;

  @override
  CompressionResult compress(List<int> input, CompressionType type) =>
      _manager.compress(input, type);

  @override
  CompressionResult decompress(
    List<int> input, {
    required CompressionType type,
    required int originalSize,
  }) =>
      _manager.decompress(input, type: type, originalSize: originalSize);
}

/// Rust backend for compression.
class RustCompressionService implements CompressionService {
  const RustCompressionService(this._api);

  final PhotonLinkCoreApi _api;

  @override
  CompressionResult compress(List<int> input, CompressionType type) {
    final result = _api.compressData(
      Uint8List.fromList(input),
      type.id,
    );
    return CompressionResult(
      type: type,
      originalSize: result.originalSize,
      outputSize: result.outputSize,
      bytes: result.bytes,
    );
  }

  @override
  CompressionResult decompress(
    List<int> input, {
    required CompressionType type,
    required int originalSize,
  }) {
    final result = _api.decompressData(
      Uint8List.fromList(input),
      kind: type.id,
      originalSize: originalSize,
    );
    return CompressionResult(
      type: type,
      originalSize: originalSize,
      outputSize: result.outputSize,
      bytes: result.bytes,
    );
  }
}
