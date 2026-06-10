import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/services/storage/preferences_service.dart';
import 'package:photonlink_app/transfer/persistence/session_persistence_manager_impl.dart';
import 'package:photonlink_app/transfer/reliability/models/persisted_session.dart';
import 'package:photonlink_app/transfer/reliability/models/transfer_diagnostics.dart';
import 'package:photonlink_app/transfer/state/transfer_phase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sha256 =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

PersistedSession _sampleSession({
  required String sessionId,
  required TransferRole role,
  required TransferPhase phase,
  List<int> receivedChunkIds = const [],
}) {
  return PersistedSession(
    sessionId: sessionId,
    role: role,
    phase: phase,
    fileName: 'test.txt',
    fileSize: 1024,
    totalChunks: 5,
    sha256: _sha256,
    mimeType: 'text/plain',
    receivedChunkIds: receivedChunkIds,
    acknowledgedChunkIds: const [],
    progress: receivedChunkIds.length / 5,
    diagnostics: const TransferDiagnostics(),
  );
}

void main() {
  late SessionPersistenceManagerImpl persistence;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    persistence = SessionPersistenceManagerImpl(prefs);
  });

  test('save load and remove session', () async {
    final session = _sampleSession(
      sessionId: 'persist-1',
      role: TransferRole.receiver,
      phase: TransferPhase.receiving,
      receivedChunkIds: [0, 1],
    );

    await persistence.save(session);
    final loaded = await persistence.load('persist-1');
    expect(loaded?.sessionId, 'persist-1');
    expect(loaded?.receivedChunkIds, [0, 1]);

    final resumable = await persistence.listResumable();
    expect(resumable.length, 1);

    await persistence.remove('persist-1');
    expect(await persistence.load('persist-1'), isNull);
    expect(await persistence.listResumable(), isEmpty);
  });

  test('findLatestResumable filters by role', () async {
    await persistence.save(
      _sampleSession(
        sessionId: 'sender-1',
        role: TransferRole.sender,
        phase: TransferPhase.transmitting,
      ),
    );
    await persistence.save(
      _sampleSession(
        sessionId: 'recv-1',
        role: TransferRole.receiver,
        phase: TransferPhase.receiving,
        receivedChunkIds: [0],
      ),
    );

    final latest = await persistence.findLatestResumable(
      role: TransferRole.receiver,
    );
    expect(latest?.sessionId, 'recv-1');
  });
}
