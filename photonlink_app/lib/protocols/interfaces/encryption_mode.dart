/// Encryption mode identifier (transport-agnostic).
enum EncryptionMode {
  disabled('disabled'),
  enabled('enabled');

  const EncryptionMode(this.id);
  final String id;

  static EncryptionMode fromId(String? id) {
    if (id == null) return EncryptionMode.disabled;
    return EncryptionMode.values.firstWhere(
      (t) => t.id == id,
      orElse: () => EncryptionMode.disabled,
    );
  }
}
