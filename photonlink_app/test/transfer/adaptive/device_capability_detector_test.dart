import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/adaptive/device_capability_detector.dart';
import 'package:photonlink_app/transfer/adaptive/models/capability_profile.dart';

void main() {
  test('detect returns profile with camera dimensions', () async {
    final detector = DeviceCapabilityDetector();
    final profile = await detector.detect(
      cameraWidth: 1920,
      cameraHeight: 1080,
      cameraResolutionPreset: 'high',
    );

    expect(profile.cameraWidth, 1920);
    expect(profile.cameraHeight, 1080);
    expect(profile.cpuCores, greaterThan(0));
    expect(profile.displayRefreshRate, greaterThan(0));
  });

  test('classifies device from capability signals', () async {
    final detector = DeviceCapabilityDetector();
    final profile = await detector.detect(
      cameraResolutionPreset: 'medium',
    );
    expect(profile.deviceClass, isA<DeviceClass>());
  });
}
