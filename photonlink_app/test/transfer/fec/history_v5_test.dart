import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/history/domain/transfer_record.dart';
import 'package:photonlink_app/protocols/transfer_method.dart';
import 'package:photonlink_app/services/storage/preferences_service.dart';
import 'package:photonlink_app/history/data/persistent_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('History v5', () {
    test('stores and loads FEC fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      final repo = PersistentHistoryRepository(prefs);

      final record = TransferRecord(
        id: 'fec-test-1',
        fileName: 'test.bin',
        method: TransferMethod.qr,
        sizeBytes: 1024,
        status: TransferStatus.success,
        timestamp: DateTime(2026, 1, 1),
        direction: TransferDirection.received,
        protocolVersion: 5,
        fecProfile: 'balanced',
        packetsRecovered: 3,
        recoveryRate: 0.75,
        parityOverhead: 0.1,
      );

      await repo.addRecord(record);
      final all = await repo.fetchAll();
      final found = all.firstWhere((r) => r.id == 'fec-test-1');
      expect(found.protocolVersion, 5);
      expect(found.fecProfile, 'balanced');
      expect(found.packetsRecovered, 3);
      expect(found.recoveryRate, 0.75);
      expect(found.parityOverhead, 0.1);
    });
  });
}
