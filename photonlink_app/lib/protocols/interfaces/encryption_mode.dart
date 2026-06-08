/// Supported payload encryption modes.
enum EncryptionMode {
  none('none'),
  chacha20Poly1305('chacha20_poly1305');

  const EncryptionMode(this.id);
  final String id;

  static EncryptionMode fromId(String? id) {
    if (id == null) return EncryptionMode.none;
    return EncryptionMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => EncryptionMode.none,
    );
  }
}
