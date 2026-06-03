import 'dart:typed_data';

import '../../transfer/core/chunking_engine.dart';
import '../../transfer/core/integrity_verifier.dart';
import '../../transfer/core/session_factory.dart';
import '../../transfer/qr/qr_frame_codec.dart';
import '../interfaces/checksum_validator.dart';
import '../interfaces/decoder.dart';
import '../interfaces/encoder.dart';
import '../interfaces/packetizer.dart';
import '../interfaces/session_manager.dart';
import '../interfaces/transfer_decoder.dart';
import '../interfaces/transfer_encoder.dart';
import '../interfaces/transfer_packet.dart';
import '../models/protocol_models.dart';

/// QR protocol facade — delegates to Phase 2 transport-independent core.
class QrProtocol
    implements
        Encoder<Uint8List, String>,
        Decoder<String, TransferPacket>,
        Packetizer,
        ChecksumValidator,
        SessionManager {
  QrProtocol({
    ChunkingEngine? chunkingEngine,
    IntegrityVerifier? integrityVerifier,
    SessionFactory? sessionFactory,
    QrFrameCodec? codec,
  })  : _chunking = chunkingEngine ?? const ChunkingEngine(),
        _integrity = integrityVerifier ?? const IntegrityVerifier(),
        _sessionFactory = sessionFactory ?? SessionFactory(),
        _codec = codec ?? const QrFrameCodec();

  final ChunkingEngine _chunking;
  final IntegrityVerifier _integrity;
  final SessionFactory _sessionFactory;
  final QrFrameCodec _codec;

  TransferEncoder get encoder => _codec;
  TransferDecoder get decoder => _codec;

  @override
  Stream<String> encode(Uint8List input) async* {
    final bundle = _sessionFactory.prepareSenderSession(
      fileBytes: input,
      fileName: 'file',
      mimeType: 'application/octet-stream',
    );
    for (final packet in bundle.allPackets) {
      yield _codec.encodeFrame(packet);
    }
  }

  @override
  Stream<TransferPacket> decode(Stream<String> input) async* {
    await for (final frame in input) {
      final packet = _codec.decodeFrame(frame);
      if (packet != null) yield packet;
    }
  }

  @override
  Iterable<Packet> packetize(Uint8List data) {
    final sessionId = _sessionFactory.generateSessionId();
    final dataPackets = _chunking.split(data: data, sessionId: sessionId);
    return dataPackets.map(
      (p) => Packet(
        index: p.chunkId,
        total: p.totalChunks,
        payload: p.payload,
        checksum: 0,
      ),
    );
  }

  @override
  Uint8List assemble(Iterable<Packet> packets) {
    final dataPackets = packets
        .map(
          (p) => DataPacket(
            sessionId: '',
            chunkId: p.index,
            totalChunks: p.total,
            payload: p.payload,
          ),
        )
        .toList();
    return _chunking.merge(dataPackets);
  }

  @override
  int compute(Uint8List data) => _integrity.compute(data).hashCode;

  @override
  bool validate(Uint8List data, int expected) =>
      _integrity.compute(data).hashCode == expected;

  final _sessions = <String, Session>{};
  final _eventControllers = <String, Stream<SessionEvent>>{};

  @override
  Future<Session> open(TransferDescriptor descriptor) async {
    final id = _sessionFactory.generateSessionId();
    final session = Session(
      id: id,
      descriptor: descriptor,
      startedAt: DateTime.now(),
    );
    _sessions[id] = session;
    return session;
  }

  @override
  Future<void> close(String sessionId) async {
    _sessions.remove(sessionId);
  }

  @override
  Stream<SessionEvent> events(String sessionId) {
    return _eventControllers[sessionId] ?? const Stream.empty();
  }
}
