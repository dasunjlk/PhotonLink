/// Transport pacing profile for the adaptive engine.
enum TransportProfile {
  safe('safe'),
  balanced('balanced'),
  performance('performance');

  const TransportProfile(this.id);
  final String id;

  static TransportProfile fromId(String? id) {
    if (id == null) return TransportProfile.balanced;
    return TransportProfile.values.firstWhere(
      (p) => p.id == id,
      orElse: () => TransportProfile.balanced,
    );
  }
}

/// Manual profile override — auto lets the engine decide.
enum ProfileOverride {
  auto('auto'),
  safe('safe'),
  balanced('balanced'),
  performance('performance');

  const ProfileOverride(this.id);
  final String id;

  TransportProfile? get forcedProfile => switch (this) {
        ProfileOverride.auto => null,
        ProfileOverride.safe => TransportProfile.safe,
        ProfileOverride.balanced => TransportProfile.balanced,
        ProfileOverride.performance => TransportProfile.performance,
      };

  static ProfileOverride fromId(String? id) {
    if (id == null) return ProfileOverride.auto;
    return ProfileOverride.values.firstWhere(
      (p) => p.id == id,
      orElse: () => ProfileOverride.auto,
    );
  }
}

/// How aggressively the engine adjusts parameters.
enum AdaptiveAggressiveness {
  gentle('gentle', cooldownMs: 8000, hysteresisSamples: 8),
  normal('normal', cooldownMs: 5000, hysteresisSamples: 5),
  aggressive('aggressive', cooldownMs: 3000, hysteresisSamples: 3);

  const AdaptiveAggressiveness(
    this.id, {
    required this.cooldownMs,
    required this.hysteresisSamples,
  });

  final String id;
  final int cooldownMs;
  final int hysteresisSamples;

  static AdaptiveAggressiveness fromId(String? id) {
    if (id == null) return AdaptiveAggressiveness.normal;
    return AdaptiveAggressiveness.values.firstWhere(
      (a) => a.id == id,
      orElse: () => AdaptiveAggressiveness.normal,
    );
  }
}
