import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/serialization/packet_id_ranges.dart';

void main() {
  test('range encode decode roundtrip', () {
    const ids = [0, 1, 2, 7, 9, 10, 11];
    final encoded = PacketIdRanges.encode(ids);
    expect(encoded, '0-2,7,9-11');
    expect(PacketIdRanges.decode(encoded), ids);
  });

  test('range encoding smaller than json array', () {
    final ids = List.generate(200, (i) => i);
    final range = PacketIdRanges.encode(ids);
    final json = PacketIdRanges.encodeJsonArray(ids);
    expect(range.length, lessThan(json.length));
    expect(utf8.encode(range).length, lessThan(utf8.encode(json).length));
  });
}
