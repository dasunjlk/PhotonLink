import 'transfer_packet.dart';

/// Decodes transport-specific frame strings into transfer packets.
abstract interface class TransferDecoder {
  /// Returns null for unrecognized or malformed frames.
  TransferPacket? decodeFrame(String raw);
}
