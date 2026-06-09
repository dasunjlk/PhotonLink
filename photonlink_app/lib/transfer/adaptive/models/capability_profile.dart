/// Device capability snapshot for adaptive decisions.
class CapabilityProfile {
  const CapabilityProfile({
    this.cameraWidth = 0,
    this.cameraHeight = 0,
    this.cameraFpsEstimate = 0,
    this.displayWidth = 0,
    this.displayHeight = 0,
    this.displayRefreshRate = 60,
    this.cpuCores = 1,
    this.cpuModel = 'unknown',
    this.totalMemoryMb = 0,
    this.deviceClass = DeviceClass.unknown,
    this.platform = 'unknown',
  });

  final int cameraWidth;
  final int cameraHeight;
  final double cameraFpsEstimate;
  final double displayWidth;
  final double displayHeight;
  final double displayRefreshRate;
  final int cpuCores;
  final String cpuModel;
  final int totalMemoryMb;
  final DeviceClass deviceClass;
  final String platform;

  Map<String, dynamic> toJson() => {
        'cameraWidth': cameraWidth,
        'cameraHeight': cameraHeight,
        'cameraFpsEstimate': cameraFpsEstimate,
        'displayWidth': displayWidth,
        'displayHeight': displayHeight,
        'displayRefreshRate': displayRefreshRate,
        'cpuCores': cpuCores,
        'cpuModel': cpuModel,
        'totalMemoryMb': totalMemoryMb,
        'deviceClass': deviceClass.name,
        'platform': platform,
      };

  factory CapabilityProfile.fromJson(Map<String, dynamic> json) {
    return CapabilityProfile(
      cameraWidth: json['cameraWidth'] as int? ?? 0,
      cameraHeight: json['cameraHeight'] as int? ?? 0,
      cameraFpsEstimate:
          (json['cameraFpsEstimate'] as num?)?.toDouble() ?? 0,
      displayWidth: (json['displayWidth'] as num?)?.toDouble() ?? 0,
      displayHeight: (json['displayHeight'] as num?)?.toDouble() ?? 0,
      displayRefreshRate:
          (json['displayRefreshRate'] as num?)?.toDouble() ?? 60,
      cpuCores: json['cpuCores'] as int? ?? 1,
      cpuModel: json['cpuModel'] as String? ?? 'unknown',
      totalMemoryMb: json['totalMemoryMb'] as int? ?? 0,
      deviceClass: DeviceClass.values.firstWhere(
        (c) => c.name == json['deviceClass'],
        orElse: () => DeviceClass.unknown,
      ),
      platform: json['platform'] as String? ?? 'unknown',
    );
  }
}

enum DeviceClass {
  low,
  mid,
  high,
  unknown,
}
