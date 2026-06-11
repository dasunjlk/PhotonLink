import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../../transfer/adaptive/models/environment_profile.dart';
import '../../transfer/adaptive/models/quality_score.dart';
import '../../transfer/fec/models/fec_statistics.dart';

/// Diagnostics calculations (Phase 8B).
abstract interface class DiagnosticsService {
  QualityScore calculateQualityScore({
    required FrameDiagnostics diagnostics,
    required EnvironmentProfile environment,
    FecStatistics? fecStats,
  });
}
