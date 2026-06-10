/// Supported erasure codec implementations.
enum FecCodecType {
  reedSolomon('reed_solomon'),
  /// Reserved for future Phase 8+ fountain codes.
  ltCodes('lt_codes'),
  raptor('raptor'),
  raptorQ('raptor_q');

  const FecCodecType(this.id);

  final String id;

  static FecCodecType fromId(String? id) {
    if (id == null) return FecCodecType.reedSolomon;
    return FecCodecType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => FecCodecType.reedSolomon,
    );
  }
}
