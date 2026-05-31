import 'dart:typed_data';

import '../models/protocol_models.dart';

/// Splits raw bytes into packets and reassembles them.
abstract interface class Packetizer {
  Iterable<Packet> packetize(Uint8List data);
  Uint8List assemble(Iterable<Packet> packets);
}
