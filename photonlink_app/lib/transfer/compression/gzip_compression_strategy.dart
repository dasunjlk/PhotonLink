import 'dart:io';
import 'dart:typed_data';

import '../../protocols/interfaces/compression_type.dart';
import 'compression_strategy.dart';

/// GZip compression using Dart's built-in codec.
class GzipCompressionStrategy implements CompressionStrategy {
  const GzipCompressionStrategy();

  @override
  CompressionType get type => CompressionType.gzip;

  @override
  Uint8List compress(Uint8List data) {
    return Uint8List.fromList(gzip.encode(data));
  }

  @override
  Uint8List decompress(Uint8List data) {
    return Uint8List.fromList(gzip.decode(data));
  }
}
