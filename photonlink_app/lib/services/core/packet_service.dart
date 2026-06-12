import 'dart:typed_data';

import '../../protocols/interfaces/transfer_packet.dart';
import '../../transfer/color_matrix/color_matrix_frame.dart';
import '../../transfer/optical_stream/optical_stream_frame.dart';

/// Packet serialization/deserialization (Phase 8A).
abstract interface class PacketService {
  String encodePl2Frame(TransferPacket packet);
  TransferPacket? decodePl2Frame(String raw);

  Uint8List serializePlcmFrame(ColorMatrixFrame frame);
  ColorMatrixFrame? deserializePlcmFrame(Uint8List bytes);

  Uint8List serializePlosFrame(OpticalStreamFrame frame);
  OpticalStreamFrame? deserializePlosFrame(Uint8List bytes);
}
