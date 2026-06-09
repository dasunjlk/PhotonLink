/// Payload density tier — maps to bits-per-channel on Color Matrix.
enum PayloadDensity {
  low('low', bitsPerChannel: 1),
  medium('medium', bitsPerChannel: 2),
  high('high', bitsPerChannel: 3);

  const PayloadDensity(this.id, {required this.bitsPerChannel});
  final String id;
  final int bitsPerChannel;

  static PayloadDensity fromBitsPerChannel(int bpc) {
    return PayloadDensity.values.firstWhere(
      (d) => d.bitsPerChannel == bpc,
      orElse: () => PayloadDensity.medium,
    );
  }

  static PayloadDensity fromId(String? id) {
    if (id == null) return PayloadDensity.medium;
    return PayloadDensity.values.firstWhere(
      (d) => d.id == id,
      orElse: () => PayloadDensity.medium,
    );
  }

  PayloadDensity stepDown() => switch (this) {
        PayloadDensity.high => PayloadDensity.medium,
        PayloadDensity.medium => PayloadDensity.low,
        PayloadDensity.low => PayloadDensity.low,
      };

  PayloadDensity stepUp() => switch (this) {
        PayloadDensity.low => PayloadDensity.medium,
        PayloadDensity.medium => PayloadDensity.high,
        PayloadDensity.high => PayloadDensity.high,
      };
}
