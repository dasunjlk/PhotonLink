import 'transfer_packet.dart';

/// Decodes transport-specific frame representations into transfer packets.
abstract interface class TransferDecoder<TFrame> {
  /// Returns null for unrecognized or malformed frames.
  TransferPacket? decodeFrame(TFrame raw);
}
