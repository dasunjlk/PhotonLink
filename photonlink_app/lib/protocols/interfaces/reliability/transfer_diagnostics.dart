import '../../../transfer/fec/models/fec_statistics.dart';

/// Frame-level diagnostics for optical transport (Color Matrix path).
class FrameDiagnostics {
  const FrameDiagnostics({
    this.framesGenerated = 0,
    this.framesReceived = 0,
    this.framesLost = 0,
    this.framesCorrupted = 0,
    this.framesRetried = 0,
    this.duplicatesIgnored = 0,
    this.throughputBytesPerSecond = 0.0,
    this.avgDecodeTimeMs = 0.0,
    this.detectionAccuracy = 0.0,
    this.missingPacketCount = 0,
    this.fec,
  });

  final int framesGenerated;
  final int framesReceived;
  final int framesLost;
  final int framesCorrupted;
  final int framesRetried;
  final int duplicatesIgnored;
  final double throughputBytesPerSecond;
  final double avgDecodeTimeMs;
  final double detectionAccuracy;
  final int missingPacketCount;
  final FecStatistics? fec;

  FrameDiagnostics copyWith({
    int? framesGenerated,
    int? framesReceived,
    int? framesLost,
    int? framesCorrupted,
    int? framesRetried,
    int? duplicatesIgnored,
    double? throughputBytesPerSecond,
    double? avgDecodeTimeMs,
    double? detectionAccuracy,
    int? missingPacketCount,
    FecStatistics? fec,
  }) {
    return FrameDiagnostics(
      framesGenerated: framesGenerated ?? this.framesGenerated,
      framesReceived: framesReceived ?? this.framesReceived,
      framesLost: framesLost ?? this.framesLost,
      framesCorrupted: framesCorrupted ?? this.framesCorrupted,
      framesRetried: framesRetried ?? this.framesRetried,
      duplicatesIgnored: duplicatesIgnored ?? this.duplicatesIgnored,
      throughputBytesPerSecond:
          throughputBytesPerSecond ?? this.throughputBytesPerSecond,
      avgDecodeTimeMs: avgDecodeTimeMs ?? this.avgDecodeTimeMs,
      detectionAccuracy: detectionAccuracy ?? this.detectionAccuracy,
      missingPacketCount: missingPacketCount ?? this.missingPacketCount,
      fec: fec ?? this.fec,
    );
  }

  Map<String, dynamic> toJson() => {
        'framesGenerated': framesGenerated,
        'framesReceived': framesReceived,
        'framesLost': framesLost,
        'framesCorrupted': framesCorrupted,
        'framesRetried': framesRetried,
        'duplicatesIgnored': duplicatesIgnored,
        'throughputBytesPerSecond': throughputBytesPerSecond,
        'avgDecodeTimeMs': avgDecodeTimeMs,
        'detectionAccuracy': detectionAccuracy,
        'missingPacketCount': missingPacketCount,
        if (fec != null) 'fec': fec!.toJson(),
      };

  factory FrameDiagnostics.fromJson(Map<String, dynamic> json) {
    return FrameDiagnostics(
      framesGenerated: json['framesGenerated'] as int? ?? 0,
      framesReceived: json['framesReceived'] as int? ?? 0,
      framesLost: json['framesLost'] as int? ?? 0,
      framesCorrupted: json['framesCorrupted'] as int? ?? 0,
      framesRetried: json['framesRetried'] as int? ?? 0,
      duplicatesIgnored: json['duplicatesIgnored'] as int? ?? 0,
      throughputBytesPerSecond:
          (json['throughputBytesPerSecond'] as num?)?.toDouble() ?? 0,
      avgDecodeTimeMs: (json['avgDecodeTimeMs'] as num?)?.toDouble() ?? 0,
      detectionAccuracy: (json['detectionAccuracy'] as num?)?.toDouble() ?? 0,
      missingPacketCount: json['missingPacketCount'] as int? ?? 0,
      fec: json['fec'] != null
          ? FecStatistics.fromJson(json['fec'] as Map<String, dynamic>)
          : null,
    );
  }
}
