import '../../transfer/state/transfer_phase.dart';
import '../components/photon_status_badge.dart';

/// Presentation helpers shared by the transfer (send / receive) screens.
///
/// These map backend transfer state into display strings and tones. They
/// contain no transfer logic — only formatting.
abstract final class TransferPresentation {
  static String phaseLabel(TransferPhase phase) => switch (phase) {
        TransferPhase.idle => 'Idle',
        TransferPhase.preparing => 'Preparing',
        TransferPhase.waitingForReceiver => 'Waiting',
        TransferPhase.transmitting => 'Transmitting',
        TransferPhase.receiving => 'Receiving',
        TransferPhase.awaitingAcknowledgements => 'Awaiting ACK',
        TransferPhase.recoveringMissingPackets => 'Recovering',
        TransferPhase.paused => 'Paused',
        TransferPhase.resuming => 'Resuming',
        TransferPhase.reconstructing => 'Reconstructing',
        TransferPhase.completed => 'Completed',
        TransferPhase.failed => 'Failed',
        TransferPhase.cancelled => 'Cancelled',
      };

  static PhotonStatusTone phaseTone(TransferPhase phase) => switch (phase) {
        TransferPhase.completed => PhotonStatusTone.success,
        TransferPhase.failed => PhotonStatusTone.error,
        TransferPhase.cancelled => PhotonStatusTone.warning,
        TransferPhase.paused => PhotonStatusTone.warning,
        TransferPhase.idle => PhotonStatusTone.neutral,
        _ => PhotonStatusTone.info,
      };

  static String formatBytes(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '—';
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  }
}
