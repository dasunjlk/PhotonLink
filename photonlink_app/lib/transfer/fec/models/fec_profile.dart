/// Predefined FEC protection profiles with redundancy percentages.
enum FecProfile {
  lowProtection('low', 'Low Protection', 5),
  balanced('balanced', 'Balanced', 10),
  highProtection('high', 'High Protection', 20),
  maximumReliability('maximum', 'Maximum Reliability', 30),
  auto('auto', 'Automatic', 10);

  const FecProfile(this.id, this.label, this.defaultRedundancyPercent);

  final String id;
  final String label;

  /// Default redundancy percentage for this profile.
  final int defaultRedundancyPercent;

  static FecProfile fromId(String? id) {
    if (id == null) return FecProfile.balanced;
    return FecProfile.values.firstWhere(
      (p) => p.id == id,
      orElse: () => FecProfile.balanced,
    );
  }

  /// Resolves effective redundancy when profile is [auto].
  int resolveRedundancy({int? overridePercent}) {
    if (this == FecProfile.auto) {
      return overridePercent ?? FecProfile.balanced.defaultRedundancyPercent;
    }
    return defaultRedundancyPercent;
  }
}
