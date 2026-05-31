import '../models/protocol_models.dart';

/// Manages the lifecycle of optical transfer sessions.
abstract interface class SessionManager {
  Future<Session> open(TransferDescriptor descriptor);
  Future<void> close(String sessionId);
  Stream<SessionEvent> events(String sessionId);
}
