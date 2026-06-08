import '../../protocols/interfaces/transport.dart';
import '../../protocols/transfer_method.dart';
import '../core/transfer_limits.dart';
import 'color_matrix_frame.dart';
import 'color_matrix_frame_codec.dart';
import 'color_matrix_transfer_limits.dart';

/// Color Matrix optical transport bundle.
class ColorMatrixTransport implements Transport<ColorMatrixFrame> {
  ColorMatrixTransport({
    int gridSize = 16,
    int bitsPerChannel = 2,
    ColorMatrixFrameCodec? codec,
    ColorMatrixTransferLimitsResolver? limits,
  })  : _codec = codec ??
            ColorMatrixFrameCodec(
              gridSize: gridSize,
              bitsPerChannel: bitsPerChannel,
            ),
        _limits = limits ??
            ColorMatrixTransferLimitsResolver(
              gridSize: gridSize,
              bitsPerChannel: bitsPerChannel,
            );

  final ColorMatrixFrameCodec _codec;
  final ColorMatrixTransferLimitsResolver _limits;

  @override
  TransferMethod get method => TransferMethod.colorMatrix;

  @override
  ColorMatrixFrameCodec get encoder => _codec;

  @override
  ColorMatrixFrameCodec get decoder => _codec;

  @override
  ColorMatrixTransferLimitsResolver get limits => _limits;

  @override
  TransportCapabilities get capabilities => const TransportCapabilities(
        supportsCompression: true,
        supportsEncryption: true,
        supportsReliabilityFeedback: false,
        defaultFramesPerSecond: 4.0,
        maxFileBytes: TransferLimits.maxColorMatrixFileBytes,
      );
}
