import '../../protocols/interfaces/transfer_decoder.dart';
import '../../protocols/interfaces/transfer_encoder.dart';
import '../../protocols/interfaces/transport.dart';
import '../../protocols/transfer_method.dart';
import '../core/transfer_limits.dart';
import 'optical_stream_frame.dart';
import 'optical_stream_codec.dart';
import 'optical_stream_transfer_limits.dart';

/// Optical Stream continuous transport bundle.
class OpticalStreamTransport implements Transport<OpticalStreamFrame> {
  OpticalStreamTransport({
    int gridSize = 24,
    int bitsPerCell = 3,
    OpticalStreamFrameCodec? codec,
    OpticalStreamTransferLimitsResolver? limits,
  })  : _codec = codec ??
            OpticalStreamFrameCodec(
              gridSize: gridSize,
              bitsPerCell: bitsPerCell,
            ),
        _limits = limits ??
            OpticalStreamTransferLimitsResolver(
              gridSize: gridSize,
              bitsPerCell: bitsPerCell,
            );

  final OpticalStreamFrameCodec _codec;
  final OpticalStreamTransferLimitsResolver _limits;

  @override
  TransferMethod get method => TransferMethod.opticalStream;

  @override
  TransferEncoder<OpticalStreamFrame> get encoder => _codec;

  @override
  TransferDecoder<OpticalStreamFrame> get decoder => _codec;

  @override
  OpticalStreamTransferLimitsResolver get limits => _limits;

  @override
  TransportCapabilities get capabilities => const TransportCapabilities(
        supportsCompression: true,
        supportsEncryption: true,
        supportsReliabilityFeedback: false,
        defaultFramesPerSecond: 8.0,
        maxFileBytes: TransferLimits.maxOpticalStreamFileBytes,
      );
}
