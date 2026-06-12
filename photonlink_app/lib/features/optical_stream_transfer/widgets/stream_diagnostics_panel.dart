import 'package:flutter/material.dart';

import '../../../shared/components/components.dart';
import '../../../transfer/adaptive/models/quality_score.dart';
import '../../../ui/spacing.dart';

/// Live stream diagnostics for Optical Stream transfer screens.
class StreamDiagnosticsPanel extends StatelessWidget {
  const StreamDiagnosticsPanel({
    required this.frameRate,
    required this.throughputBytesPerSec,
    required this.recoveredPackets,
    required this.recoveryRate,
    required this.droppedFrames,
    required this.qualityScore,
    this.syncLocked = false,
    this.resyncCount = 0,
    super.key,
  });

  final double frameRate;
  final double throughputBytesPerSec;
  final int recoveredPackets;
  final double recoveryRate;
  final int droppedFrames;
  final QualityScore qualityScore;
  final bool syncLocked;
  final int resyncCount;

  @override
  Widget build(BuildContext context) {
    return PhotonCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotonSectionHeader(
            title: 'Stream Diagnostics',
            subtitle: syncLocked ? 'Sync locked' : 'Searching for stream',
          ),
          const SizedBox(height: AppSpacing.sm),
          _row('Frame Rate', '${frameRate.toStringAsFixed(1)} fps'),
          _row('Throughput', _formatThroughput(throughputBytesPerSec)),
          _row('Recovery', '$recoveredPackets packets '
              '(${(recoveryRate * 100).toStringAsFixed(0)}%)'),
          _row('Dropped Frames', '$droppedFrames'),
          _row('Resync Events', '$resyncCount'),
          _row('Quality Score', qualityScore.score.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatThroughput(double bps) {
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) {
      return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bps / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }
}
