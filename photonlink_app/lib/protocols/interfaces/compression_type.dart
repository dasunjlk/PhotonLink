/// Supported payload compression algorithms.
enum CompressionType {
  none('none'),
  gzip('gzip');

  const CompressionType(this.id);
  final String id;

  static CompressionType fromId(String? id) {
    if (id == null) return CompressionType.none;
    return CompressionType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => CompressionType.none,
    );
  }
}
