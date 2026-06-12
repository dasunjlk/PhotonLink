import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/history/data/persistent_history_repository.dart';
import 'package:photonlink_app/history/domain/transfer_record.dart';
import 'package:photonlink_app/protocols/transfer_method.dart';
import 'package:photonlink_app/services/storage/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('updateRecord preserves FEC fields', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final repo = PersistentHistoryRepository(prefs);

    await repo.addRecord(
      TransferRecord(
        id: 'fec-1',
        fileName: 'data.bin',
        method: TransferMethod.qr,
        sizeBytes: 100,
        status: TransferStatus.inProgress,
        timestamp: DateTime.now(),
        direction: TransferDirection.sent,
        protocolVersion: 3,
        fecProfile: 'balanced',
        packetsRecovered: 2,
        recoveryRate: 0.5,
        parityOverhead: 0.1,
      ),
    );

    await repo.updateRecord('fec-1', status: TransferStatus.success);

    final records = await repo.fetchAll();
    expect(records.single.fecProfile, 'balanced');
    expect(records.single.packetsRecovered, 2);
    expect(records.single.recoveryRate, 0.5);
    expect(records.single.parityOverhead, 0.1);
  });

  test('empty history returns no seed records', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final repo = PersistentHistoryRepository(prefs);

    final records = await repo.fetchAll();
    expect(records, isEmpty);
  });
}
