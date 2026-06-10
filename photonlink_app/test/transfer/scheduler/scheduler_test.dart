import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/scheduler/transfer_mode.dart';
import 'package:photonlink_app/transfer/scheduler/transfer_scheduler.dart';

void main() {
  const scheduler = TransferScheduler();

  test('data round queue ends with endOfRound', () {
    final packets = [
      DataPacket(
        sessionId: 's',
        chunkId: 1,
        totalChunks: 3,
        payload: Uint8List.fromList([1]),
      ),
    ];
    final q = scheduler.buildDataRoundQueue(
      packetsToSend: packets,
      sessionId: 's',
    );
    expect(q.last, isA<ControlPacket>());
    expect((q.last as ControlPacket).type, ControlType.endOfRound);
  });

  test('performance mode has higher fps', () {
    expect(
      TransferMode.performance.framesPerSecond,
      greaterThan(TransferMode.normal.framesPerSecond),
    );
  });
}
