import '../../../transfer/reliability/models/persisted_session.dart';
import '../../../transfer/state/transfer_phase.dart';

/// Persists and restores in-progress transfer sessions.
abstract interface class SessionPersistenceManager {
  Future<void> save(PersistedSession session);

  Future<PersistedSession?> load(String sessionId);

  Future<List<PersistedSession>> listResumable();

  Future<void> remove(String sessionId);

  Future<PersistedSession?> findLatestResumable({
    required TransferRole role,
  });
}
