import '../../../protocols/interfaces/encryption_mode.dart';

/// Metadata describing how a payload was encrypted.
class EncryptedPacketMetadata {
  const EncryptedPacketMetadata({
    required this.mode,
    required this.protocolVersion,
    this.nonceLength = 12,
    this.tagLength = 16,
  });

  final EncryptionMode mode;
  final int protocolVersion;
  final int nonceLength;
  final int tagLength;

  Map<String, dynamic> toJson() => {
        'mode': mode.id,
        'protocolVersion': protocolVersion,
        'nonceLength': nonceLength,
        'tagLength': tagLength,
      };
}
