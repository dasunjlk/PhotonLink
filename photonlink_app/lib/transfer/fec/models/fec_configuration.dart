import 'fec_codec_type.dart';
import 'fec_profile.dart';

/// Runtime FEC configuration for a transfer session.
class FecConfiguration {
  const FecConfiguration({
    this.enabled = false,
    this.profile = FecProfile.balanced,
    this.redundancyPercent = 10,
    this.blockSize = 10,
    this.codecType = FecCodecType.reedSolomon,
  });

  final bool enabled;
  final FecProfile profile;
  final int redundancyPercent;
  final int blockSize;
  final FecCodecType codecType;

  /// Maximum data symbols per RS block (GF(256) limit).
  static const int maxBlockSize = 255;

  /// Computes parity count for a block of [dataCount] data packets.
  int parityCountForBlock(int dataCount) {
    if (!enabled || dataCount < 1) return 0;
    final percent = profile.resolveRedundancy(
      overridePercent: redundancyPercent,
    );
    return (dataCount * percent / 100).ceil().clamp(1, maxBlockSize - dataCount);
  }

  /// Total parity packets for [totalDataChunks] data chunks.
  int totalParityCount(int totalDataChunks) {
    if (!enabled || totalDataChunks < 1) return 0;
    var parity = 0;
    var offset = 0;
    while (offset < totalDataChunks) {
      final k = (offset + blockSize <= totalDataChunks)
          ? blockSize
          : totalDataChunks - offset;
      parity += parityCountForBlock(k);
      offset += k;
    }
    return parity;
  }

  FecConfiguration copyWith({
    bool? enabled,
    FecProfile? profile,
    int? redundancyPercent,
    int? blockSize,
    FecCodecType? codecType,
  }) {
    return FecConfiguration(
      enabled: enabled ?? this.enabled,
      profile: profile ?? this.profile,
      redundancyPercent: redundancyPercent ?? this.redundancyPercent,
      blockSize: blockSize ?? this.blockSize,
      codecType: codecType ?? this.codecType,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'profile': profile.id,
        'redundancyPercent': redundancyPercent,
        'blockSize': blockSize,
        'codecType': codecType.id,
      };

  factory FecConfiguration.fromJson(Map<String, dynamic> json) {
    return FecConfiguration(
      enabled: json['enabled'] as bool? ?? false,
      profile: FecProfile.fromId(json['profile'] as String?),
      redundancyPercent: json['redundancyPercent'] as int? ?? 10,
      blockSize: json['blockSize'] as int? ?? 10,
      codecType: FecCodecType.fromId(json['codecType'] as String?),
    );
  }
}
