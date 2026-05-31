import 'dart:typed_data';

import '../interfaces/checksum_validator.dart';
import '../interfaces/decoder.dart';
import '../interfaces/encoder.dart';
import '../interfaces/packetizer.dart';
import '../interfaces/session_manager.dart';
import '../models/protocol_models.dart';

/// Placeholder QR protocol — Phase 2 will implement real encoding/decoding.
class QrProtocol
    implements
        Encoder<Uint8List, Uint8List>,
        Decoder<Uint8List, Uint8List>,
        Packetizer,
        ChecksumValidator,
        SessionManager {
  @override
  Stream<Uint8List> encode(Uint8List input) =>
      throw UnimplementedError('QR encoding — Phase 2');

  @override
  Stream<Uint8List> decode(Stream<Uint8List> input) =>
      throw UnimplementedError('QR decoding — Phase 2');

  @override
  Iterable<Packet> packetize(Uint8List data) =>
      throw UnimplementedError('QR packetizer — Phase 2');

  @override
  Uint8List assemble(Iterable<Packet> packets) =>
      throw UnimplementedError('QR assembler — Phase 2');

  @override
  int compute(Uint8List data) =>
      throw UnimplementedError('QR checksum — Phase 2');

  @override
  bool validate(Uint8List data, int expected) =>
      throw UnimplementedError('QR validation — Phase 2');

  @override
  Future<Session> open(TransferDescriptor descriptor) =>
      throw UnimplementedError('QR session — Phase 2');

  @override
  Future<void> close(String sessionId) =>
      throw UnimplementedError('QR session close — Phase 2');

  @override
  Stream<SessionEvent> events(String sessionId) =>
      throw UnimplementedError('QR session events — Phase 2');
}
