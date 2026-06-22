/// Sanitizes a transfer filename for safe local filesystem writes.
String safeTransferFilename(String fileName) {
  final trimmed = fileName.trim();
  if (trimmed.isEmpty) return 'received_file';

  final normalized = trimmed.replaceAll('\\', '/');
  final base = normalized.split('/').last;
  if (base.isEmpty || base == '.' || base == '..') {
    return 'received_file';
  }

  var sanitized = base.replaceAll(RegExp(r'[^\w.\-]'), '_');
  if (sanitized.startsWith('.')) {
    sanitized = 'file$sanitized';
  }
  if (sanitized == '..' || sanitized.isEmpty) {
    return 'received_file';
  }
  return sanitized;
}
