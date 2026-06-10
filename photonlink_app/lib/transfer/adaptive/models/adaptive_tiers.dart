/// Abstract resolution tier (transport-agnostic).
enum ResolutionTier {
  small(0),
  medium(1),
  large(2),
  extraLarge(3);

  const ResolutionTier(this.level);
  final int level;

  ResolutionTier stepDown() => ResolutionTier.values[
      (level - 1).clamp(0, ResolutionTier.values.length - 1)];

  ResolutionTier stepUp() => ResolutionTier.values[
      (level + 1).clamp(0, ResolutionTier.values.length - 1)];
}

/// Abstract frame-rate tier (transport-agnostic).
enum RateTier {
  slow(0),
  normal(1),
  fast(2),
  max(3);

  const RateTier(this.level);
  final int level;

  RateTier stepDown() =>
      RateTier.values[(level - 1).clamp(0, RateTier.values.length - 1)];

  RateTier stepUp() =>
      RateTier.values[(level + 1).clamp(0, RateTier.values.length - 1)];
}
