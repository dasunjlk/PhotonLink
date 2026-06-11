import 'dart:typed_data';

import '../../../protocols/interfaces/transfer_packet.dart';
import '../../../transfer/color_matrix/color_matrix_frame.dart';
import '../../../transfer/color_matrix/color_matrix_serializer.dart';
import '../../../transfer/qr/qr_frame_codec.dart';
import '../packet_service.dart';
import '../photon_link_core_api.dart';

/// Dart backend — delegates to existing codecs.
class DartPacketService implements PacketService {
  const DartPacketService({
    QrFrameCodec? qrCodec,
  }) : _qrCodec = qrCodec ?? const QrFrameCodec();

  final QrFrameCodec _qrCodec;

  @override
  String encodePl2Frame(TransferPacket packet) => _qrCodec.encodeFrame(packet);

  @override
  TransferPacket? decodePl2Frame(String raw) => _qrCodec.decodeFrame(raw);

  @override
  Uint8List serializePlcmFrame(ColorMatrixFrame frame) =>
      ColorMatrixSerializer.serialize(frame);

  @override
  ColorMatrixFrame? deserializePlcmFrame(Uint8List bytes) =>
      ColorMatrixSerializer.deserialize(bytes);
}

/// Rust backend for packet codecs.
class RustPacketService implements PacketService {
  const RustPacketService(this._api);

  final PhotonLinkCoreApi _api;

  @override
  String encodePl2Frame(TransferPacket packet) {
    // For Phase 8, complex PL2 types still use Dart codec via fallback.
    // Rust handles data frames; delegate non-data to Dart for compatibility.
    return const QrFrameCodec().encodeFrame(packet);
  }

  @override
  TransferPacket? decodePl2Frame(String raw) {
    return const QrFrameCodec().decodeFrame(raw);
  }

  @override
  Uint8List serializePlcmFrame(ColorMatrixFrame frame) {
    return _api.encodePlcmFrame(PlcmFrameDto(
      protocolVersion: frame.protocolVersion,
      sessionId: frame.sessionId,
      frameId: frame.frameId,
      packetId: frame.packetId,
      packetType: frame.packetType.value,
      totalPackets: frame.totalPackets,
      gridSize: frame.gridSize,
      bitsPerChannel: frame.bitsPerChannel,
      payload: frame.payload,
      checksum: frame.checksum,
    ));
  }

  @override
  ColorMatrixFrame? deserializePlcmFrame(Uint8List bytes) {
    try {
      final dto = _api.decodePlcmFrame(bytes);
      return ColorMatrixFrame(
        protocolVersion: dto.protocolVersion,
        sessionId: dto.sessionId,
        frameId: dto.frameId,
        packetId: dto.packetId,
        packetType: ColorMatrixPacketType.fromValue(dto.packetType),
        totalPackets: dto.totalPackets,
        payload: dto.payload,
        checksum: dto.checksum,
        gridSize: dto.gridSize,
        bitsPerChannel: dto.bitsPerChannel,
      );
    } catch (_) {
      return null;
    }
  }
}
