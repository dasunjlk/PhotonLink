import 'transfer_phase.dart';

/// Validates and applies transfer phase transitions by role.
class TransferStateMachine {
  TransferStateMachine({
    required this.role,
    TransferPhase initial = TransferPhase.idle,
  }) : _phase = initial;

  final TransferRole role;
  TransferPhase _phase;

  TransferPhase get phase => _phase;

  static const _commonTransitions = <TransferPhase, Set<TransferPhase>>{
    TransferPhase.idle: {
      TransferPhase.preparing,
      TransferPhase.waitingForReceiver,
      TransferPhase.resuming,
    },
    TransferPhase.preparing: {TransferPhase.waitingForReceiver, TransferPhase.failed},
    TransferPhase.waitingForReceiver: {
      TransferPhase.transmitting,
      TransferPhase.receiving,
      TransferPhase.paused,
      TransferPhase.failed,
      TransferPhase.cancelled,
    },
    TransferPhase.transmitting: {
      TransferPhase.awaitingAcknowledgements,
      TransferPhase.recoveringMissingPackets,
      TransferPhase.paused,
      TransferPhase.failed,
      TransferPhase.cancelled,
    },
    TransferPhase.receiving: {
      TransferPhase.recoveringMissingPackets,
      TransferPhase.awaitingAcknowledgements,
      TransferPhase.reconstructing,
      TransferPhase.paused,
      TransferPhase.failed,
      TransferPhase.cancelled,
    },
    TransferPhase.awaitingAcknowledgements: {
      TransferPhase.recoveringMissingPackets,
      TransferPhase.transmitting,
      TransferPhase.receiving,
      TransferPhase.completed,
      TransferPhase.failed,
      TransferPhase.cancelled,
    },
    TransferPhase.recoveringMissingPackets: {
      TransferPhase.transmitting,
      TransferPhase.receiving,
      TransferPhase.reconstructing,
      TransferPhase.awaitingAcknowledgements,
      TransferPhase.failed,
      TransferPhase.cancelled,
    },
    TransferPhase.paused: {TransferPhase.resuming, TransferPhase.cancelled, TransferPhase.failed},
    TransferPhase.resuming: {
      TransferPhase.transmitting,
      TransferPhase.receiving,
      TransferPhase.recoveringMissingPackets,
      TransferPhase.waitingForReceiver,
      TransferPhase.failed,
    },
    TransferPhase.reconstructing: {
      TransferPhase.completed,
      TransferPhase.failed,
    },
    TransferPhase.completed: {TransferPhase.idle},
    TransferPhase.failed: {TransferPhase.idle},
    TransferPhase.cancelled: {TransferPhase.idle},
  };

  bool canTransitionTo(TransferPhase next) {
    if (_phase == next) return true;
    final allowed = _commonTransitions[_phase];
    if (allowed == null || !allowed.contains(next)) return false;
    return _roleAllows(_phase, next);
  }

  bool transition(TransferPhase next) {
    if (_phase == next) return true;
    if (!canTransitionTo(next)) return false;
    _phase = next;
    return true;
  }

  void forcePhase(TransferPhase phase) => _phase = phase;

  bool _roleAllows(TransferPhase from, TransferPhase to) {
    if (role == TransferRole.sender) {
      if (to == TransferPhase.receiving) return false;
      if (from == TransferPhase.receiving) return false;
    } else {
      if (to == TransferPhase.transmitting &&
          from != TransferPhase.recoveringMissingPackets &&
          from != TransferPhase.resuming &&
          from != TransferPhase.awaitingAcknowledgements) {
        return false;
      }
    }
    return true;
  }
}
