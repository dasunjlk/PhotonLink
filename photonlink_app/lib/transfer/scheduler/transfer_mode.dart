/// Transfer pacing mode (transport-agnostic).
enum TransferMode {
  normal('normal', framesPerSecond: 2.0, windowMultiplier: 1.0),
  performance('performance', framesPerSecond: 4.0, windowMultiplier: 1.5);

  const TransferMode(this.id, {required this.framesPerSecond, required this.windowMultiplier});

  final String id;
  final double framesPerSecond;
  final double windowMultiplier;

  static TransferMode fromId(String? id) {
    if (id == null) return TransferMode.normal;
    return TransferMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => TransferMode.normal,
    );
  }
}
