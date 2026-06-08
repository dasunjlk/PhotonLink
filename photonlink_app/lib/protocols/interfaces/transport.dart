import '../transfer_method.dart';
import 'transfer_decoder.dart';
import 'transfer_encoder.dart';
import 'transport_limits_resolver.dart';

/// Capabilities exposed by a transport implementation.
class TransportCapabilities {
  const TransportCapabilities({
    required this.supportsCompression,
    required this.supportsEncryption,
    required this.supportsReliabilityFeedback,
    required this.defaultFramesPerSecond,
    required this.maxFileBytes,
  });

  final bool supportsCompression;
  final bool supportsEncryption;
  final bool supportsReliabilityFeedback;
  final double defaultFramesPerSecond;
  final int maxFileBytes;
}

/// Bundles codec and limits for a single optical transport.
abstract interface class Transport<TFrame> {
  TransferMethod get method;
  TransferEncoder<TFrame> get encoder;
  TransferDecoder<TFrame> get decoder;
  TransportLimitsResolver<TFrame> get limits;
  TransportCapabilities get capabilities;
}
