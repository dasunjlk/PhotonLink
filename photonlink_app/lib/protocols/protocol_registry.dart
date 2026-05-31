import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'impl/color_matrix_protocol.dart';
import 'impl/optical_stream_protocol.dart';
import 'impl/qr_protocol.dart';
import 'transfer_method.dart';

/// Bundles all protocol interfaces for a given transfer method.
class ProtocolBundle {
  const ProtocolBundle({
    required this.method,
    required this.encoder,
    required this.decoder,
    required this.packetizer,
    required this.checksumValidator,
    required this.sessionManager,
  });

  final TransferMethod method;
  final Object encoder;
  final Object decoder;
  final Object packetizer;
  final Object checksumValidator;
  final Object sessionManager;
}

/// Registry mapping transfer methods to their protocol implementations.
class ProtocolRegistry {
  const ProtocolRegistry(this._bundles);

  final Map<TransferMethod, ProtocolBundle> _bundles;

  ProtocolBundle get(TransferMethod method) {
    final bundle = _bundles[method];
    if (bundle == null) {
      throw StateError('No protocol registered for $method');
    }
    return bundle;
  }

  bool has(TransferMethod method) => _bundles.containsKey(method);
}

/// Provider exposing the protocol registry for dependency injection.
final protocolRegistryProvider = Provider<ProtocolRegistry>((ref) {
  return ProtocolRegistry({
    TransferMethod.qr: ProtocolBundle(
      method: TransferMethod.qr,
      encoder: QrProtocol(),
      decoder: QrProtocol(),
      packetizer: QrProtocol(),
      checksumValidator: QrProtocol(),
      sessionManager: QrProtocol(),
    ),
    TransferMethod.colorMatrix: ProtocolBundle(
      method: TransferMethod.colorMatrix,
      encoder: ColorMatrixProtocol(),
      decoder: ColorMatrixProtocol(),
      packetizer: ColorMatrixProtocol(),
      checksumValidator: ColorMatrixProtocol(),
      sessionManager: ColorMatrixProtocol(),
    ),
    TransferMethod.opticalStream: ProtocolBundle(
      method: TransferMethod.opticalStream,
      encoder: OpticalStreamProtocol(),
      decoder: OpticalStreamProtocol(),
      packetizer: OpticalStreamProtocol(),
      checksumValidator: OpticalStreamProtocol(),
      sessionManager: OpticalStreamProtocol(),
    ),
  });
});
