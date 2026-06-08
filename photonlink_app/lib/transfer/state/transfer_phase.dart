/// Transfer lifecycle phases (transport-agnostic).
enum TransferPhase {
  idle,
  preparing,
  waitingForReceiver,
  transmitting,
  receiving,
  awaitingAcknowledgements,
  recoveringMissingPackets,
  paused,
  resuming,
  reconstructing,
  completed,
  failed,
  cancelled,
}

/// Whether this device is sending or receiving.
enum TransferRole {
  sender,
  receiver,
}

extension TransferPhaseX on TransferPhase {
  bool get isTerminal =>
      this == TransferPhase.completed ||
      this == TransferPhase.failed ||
      this == TransferPhase.cancelled;

  bool get showsQrDisplay =>
      this == TransferPhase.waitingForReceiver ||
      this == TransferPhase.transmitting ||
      this == TransferPhase.awaitingAcknowledgements ||
      this == TransferPhase.recoveringMissingPackets ||
      this == TransferPhase.reconstructing ||
      this == TransferPhase.completed;

  bool get showsScanner =>
      this == TransferPhase.waitingForReceiver ||
      this == TransferPhase.receiving ||
      this == TransferPhase.awaitingAcknowledgements ||
      this == TransferPhase.resuming;
}
