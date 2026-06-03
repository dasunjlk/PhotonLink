import 'transfer_packet.dart';

/// Encodes transfer packets into transport-specific frame strings.
abstract interface class TransferEncoder {
  String encodeFrame(TransferPacket packet);
}
