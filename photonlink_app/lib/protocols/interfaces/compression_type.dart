/// Compression algorithm identifier (transport-agnostic).
enum CompressionType {
  none('none'),
  gzip('gzip'),
  lz4('lz4');

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
