import 'package:flutter_test/flutter_test.dart';
import 'package:photonlink_app/transfer/state/transfer_phase.dart';
import 'package:photonlink_app/transfer/state/transfer_state_machine.dart';

void main() {
  test('sender valid transitions', () {
    final sm = TransferStateMachine(role: TransferRole.sender);
    expect(sm.transition(TransferPhase.preparing), isTrue);
    expect(sm.transition(TransferPhase.waitingForReceiver), isTrue);
    expect(sm.transition(TransferPhase.transmitting), isTrue);
    expect(sm.transition(TransferPhase.awaitingAcknowledgements), isTrue);
    expect(sm.transition(TransferPhase.completed), isTrue);
  });

  test('invalid sender transition rejected', () {
    final sm = TransferStateMachine(role: TransferRole.sender);
    expect(sm.transition(TransferPhase.receiving), isFalse);
  });

  test('cancelled returns to idle', () {
    final sm = TransferStateMachine(role: TransferRole.sender);
    sm.transition(TransferPhase.preparing);
    sm.transition(TransferPhase.waitingForReceiver);
    sm.transition(TransferPhase.cancelled);
    expect(sm.phase, TransferPhase.cancelled);
    expect(sm.transition(TransferPhase.idle), isTrue);
  });
}
