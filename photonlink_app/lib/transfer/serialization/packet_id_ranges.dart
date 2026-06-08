import '../../protocols/interfaces/reliability/missing_packet_tracker.dart';

/// Compact range encoding for packet ID lists (e.g. "0-3,7,9-12").
abstract final class PacketIdRanges {
  static String encode(Iterable<int> ids) {
    if (ids.isEmpty) return '';
    final sorted = ids.toSet().toList()..sort();
    final ranges = <PacketIdRange>[];
    var start = sorted.first;
    var end = start;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        ranges.add(PacketIdRange(start, end));
        start = sorted[i];
        end = start;
      }
    }
    ranges.add(PacketIdRange(start, end));
    return ranges.map((r) => r.toString()).join(',');
  }

  static List<int> decode(String encoded) {
    if (encoded.isEmpty) return [];
    final ids = <int>[];
    for (final part in encoded.split(',')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length != 2) continue;
        final a = int.tryParse(bounds[0].trim());
        final b = int.tryParse(bounds[1].trim());
        if (a == null || b == null) continue;
        for (var i = a; i <= b; i++) {
          ids.add(i);
        }
      } else {
        final id = int.tryParse(trimmed);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  /// JSON array encoding for comparison benchmarks.
  static String encodeJsonArray(Iterable<int> ids) {
    return '[${ids.join(',')}]';
  }
}
