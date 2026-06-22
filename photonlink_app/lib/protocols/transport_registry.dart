import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/core/core_providers.dart';
import '../settings/application/settings_controller.dart';
import '../transfer/optical_stream/optical_stream_codec.dart';
import '../transfer/color_matrix/color_matrix_frame.dart';
import '../transfer/color_matrix/color_matrix_transport.dart';
import '../transfer/optical_stream/optical_stream_frame.dart';
import '../transfer/optical_stream/optical_stream_transport.dart';
import '../transfer/qr/qr_transport.dart';
import 'interfaces/transport.dart';
import 'transfer_method.dart';

/// Type-erased transport registry entry.
class TransportEntry {
  const TransportEntry({
    required this.method,
    required this.transport,
  });

  final TransferMethod method;
  final Transport<dynamic> transport;
}

/// Registry mapping transfer methods to transport implementations.
class TransportRegistry {
  const TransportRegistry(this._entries);

  final Map<TransferMethod, TransportEntry> _entries;

  TransportEntry get(TransferMethod method) {
    final entry = _entries[method];
    if (entry == null) {
      throw StateError('No transport registered for $method');
    }
    return entry;
  }

  bool has(TransferMethod method) => _entries.containsKey(method);

  Transport<T> transportFor<T>(TransferMethod method) {
    return get(method).transport as Transport<T>;
  }
}

/// Provider exposing the transport registry consumed by controllers.
final transportRegistryProvider = Provider<TransportRegistry>((ref) {
  final settings = ref.watch(settingsProvider);
  return TransportRegistry({
    TransferMethod.qr: TransportEntry(
      method: TransferMethod.qr,
      transport: const QrTransport(),
    ),
    TransferMethod.colorMatrix: TransportEntry(
      method: TransferMethod.colorMatrix,
      transport: ColorMatrixTransport(
        gridSize: settings.colorMatrixSize,
        bitsPerChannel: settings.colorBitsPerChannel,
      ),
    ),
    TransferMethod.opticalStream: TransportEntry(
      method: TransferMethod.opticalStream,
      transport: OpticalStreamTransport(
        gridSize: settings.opticalStreamDensity,
        bitsPerCell: 3,
        codec: OpticalStreamFrameCodec(
          gridSize: settings.opticalStreamDensity,
          bitsPerCell: 3,
          packetService: ref.watch(packetServiceProvider),
        ),
      ),
    ),
  });
});

/// Convenience accessor for Color Matrix transport.
final colorMatrixTransportProvider = Provider<ColorMatrixTransport>((ref) {
  return ref.watch(transportRegistryProvider).transportFor<ColorMatrixFrame>(
        TransferMethod.colorMatrix,
      ) as ColorMatrixTransport;
});

/// Convenience accessor for Optical Stream transport.
final opticalStreamTransportProvider = Provider<OpticalStreamTransport>((ref) {
  return ref.watch(transportRegistryProvider).transportFor<OpticalStreamFrame>(
        TransferMethod.opticalStream,
      ) as OpticalStreamTransport;
});
