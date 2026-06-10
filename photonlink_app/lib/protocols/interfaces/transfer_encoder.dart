import 'transfer_packet.dart';

/// Encodes transfer packets into transport-specific frame representations.
abstract interface class TransferEncoder<TFrame> {
  TFrame encodeFrame(TransferPacket packet);
}
