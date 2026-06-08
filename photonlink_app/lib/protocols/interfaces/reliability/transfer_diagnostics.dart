/// Structured diagnostics for a transfer session.
class TransferDiagnostics {
  const TransferDiagnostics({
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

  TransferDiagnostics copyWith({
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
  }) {
    return TransferDiagnostics(
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
      };

  factory TransferDiagnostics.fromJson(Map<String, dynamic> json) {
    return TransferDiagnostics(
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
    );
  }
}
