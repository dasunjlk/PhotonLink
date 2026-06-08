import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/services/storage/preferences_service.dart';
import 'package:photonlink_app/transfer/diagnostics/diagnostics_collector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PreferencesService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
  });

  test('records frame metrics and persists', () async {
    final collector = FrameDiagnosticsCollector(prefs);
    collector.recordFrameGenerated();
    collector.recordFrameReceived(payloadBytes: 100);
    collector.recordFrameCorrupted();
    collector.recordDetectionAccuracy(0.85);

    expect(collector.current.framesGenerated, 1);
    expect(collector.current.framesReceived, 1);
    expect(collector.current.framesCorrupted, 1);
    expect(collector.current.detectionAccuracy, 0.85);

    await collector.persist('test-session');
    final loaded = await collector.load('test-session');
    expect(loaded?.framesGenerated, 1);
    expect(loaded?.detectionAccuracy, 0.85);
  });

  test('reset clears counters', () {
    final collector = FrameDiagnosticsCollector(prefs);
    collector.recordFrameGenerated();
    collector.reset();
    expect(collector.current.framesGenerated, 0);
  });
}
