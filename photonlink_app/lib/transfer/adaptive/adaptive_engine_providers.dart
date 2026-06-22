import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adaptive_session_controller.dart';
import 'adaptive_state.dart';

/// Per-session adaptive engine for Color Matrix sender.
final colorMatrixSenderAdaptiveProvider =
    Provider<AdaptiveSessionController>((ref) {
  return AdaptiveSessionController(ref: ref);
});

/// Per-session adaptive engine for Color Matrix receiver.
final colorMatrixReceiverAdaptiveProvider =
    Provider<AdaptiveSessionController>((ref) {
  return AdaptiveSessionController(ref: ref);
});

/// Per-session adaptive engine for Optical Stream sender.
final opticalStreamSenderAdaptiveProvider =
    Provider<AdaptiveSessionController>((ref) {
  return AdaptiveSessionController(ref: ref, useOpticalMapper: true);
});

/// Per-session adaptive engine for Optical Stream receiver.
final opticalStreamReceiverAdaptiveProvider =
    Provider<AdaptiveSessionController>((ref) {
  return AdaptiveSessionController(ref: ref, useOpticalMapper: true);
});

/// Latest adaptive state snapshot (receiver-side primary).
final adaptiveStateProvider = StateProvider<AdaptiveState>(
  (ref) => const AdaptiveState(),
);
