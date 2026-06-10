import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/protocols/interfaces/transfer_packet.dart';
import 'package:photonlink_app/transfer/reliability/acknowledgement_manager_impl.dart';

void main() {
  test('ACK processing marks packets acknowledged', () {
    final mgr = AcknowledgementManagerImpl();
    mgr.reset(sessionId: 's1', totalPackets: 5);
    mgr.processAck(
      AckPacket(
        sessionId: 's1',
        packetIds: [0, 1, 2],
        timestamp: DateTime.now(),
      ),
    );
    expect(mgr.isAcknowledged(0), isTrue);
    expect(mgr.isAcknowledged(3), isFalse);
    expect(mgr.allAcknowledged, isFalse);
  });

  test('buildAck returns batch ids', () {
    final mgr = AcknowledgementManagerImpl();
    mgr.reset(sessionId: 's1', totalPackets: 2);
    mgr.recordAcknowledged(0);
    final ack = mgr.buildAck(sessionId: 's1');
    expect(ack.packetIds, [0]);
  });
}
