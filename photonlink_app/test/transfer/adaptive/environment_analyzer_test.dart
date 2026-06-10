import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/environment_analyzer.dart';

void main() {
  test('aggregates brightness and detection rates', () {
    final analyzer = EnvironmentAnalyzer(windowSize: 10);
    analyzer.recordBrightness(0.5);
    analyzer.recordBrightness(0.6);
    analyzer.recordDetectionAttempt(success: true);
    analyzer.recordDetectionAttempt(success: false);
    analyzer.recordDecodeAttempt(success: true);
    analyzer.recordDecodeAttempt(success: false);

    final profile = analyzer.current;
    expect(profile.avgBrightness, closeTo(0.55, 0.01));
    expect(profile.detectionSuccessRate, 0.5);
    expect(profile.decodeErrorRate, 0.5);
    expect(profile.samples, 2);
  });

  test('reset clears samples', () {
    final analyzer = EnvironmentAnalyzer();
    analyzer.recordBrightness(0.8);
    analyzer.reset();
    expect(analyzer.current.samples, 0);
  });
}
