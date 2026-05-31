import 'dart:typed_data';

/// A single data packet produced by the packetizer.
class Packet {
  const Packet({
    required this.index,
    required this.total,
    required this.payload,
    required this.checksum,
  });

  final int index;
  final int total;
  final Uint8List payload;
  final int checksum;
}

/// Describes a file transfer session.
class TransferDescriptor {
  const TransferDescriptor({
    required this.fileName,
    required this.sizeBytes,
    required this.mimeType,
    required this.methodId,
  });

  final String fileName;
  final int sizeBytes;
  final String mimeType;
  final String methodId;
}

/// Represents an active transfer session.
class Session {
  const Session({
    required this.id,
    required this.descriptor,
    required this.startedAt,
  });

  final String id;
  final TransferDescriptor descriptor;
  final DateTime startedAt;
}

/// Events emitted during a transfer session lifecycle.
sealed class SessionEvent {
  const SessionEvent();
}

final class SessionStarted extends SessionEvent {
  const SessionStarted(this.sessionId);
  final String sessionId;
}

final class SessionProgress extends SessionEvent {
  const SessionProgress(this.fraction);
  final double fraction;
}

final class SessionCompleted extends SessionEvent {
  const SessionCompleted();
}

final class SessionFailed extends SessionEvent {
  const SessionFailed(this.reason);
  final String reason;
}

final class SessionCancelled extends SessionEvent {
  const SessionCancelled();
}
