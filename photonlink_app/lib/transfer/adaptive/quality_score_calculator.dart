import '../../protocols/interfaces/reliability/transfer_diagnostics.dart';
import '../fec/models/fec_statistics.dart';
import 'models/environment_profile.dart';
import '../../services/core/diagnostics_service.dart';
import '../../services/core/impl/dart_diagnostics_service.dart';
import 'models/quality_score.dart';

/// Computes a 0–100 quality score from diagnostics and environment.
///
/// Delegates to [DiagnosticsService] when provided (Phase 8), otherwise
/// uses [DartDiagnosticsService] for backward compatibility.
class QualityScoreCalculator {
  const QualityScoreCalculator({DiagnosticsService? diagnosticsService})
      : _diagnosticsService = diagnosticsService;

  final DiagnosticsService? _diagnosticsService;

  QualityScore calculate({
    required FrameDiagnostics diagnostics,
    required EnvironmentProfile environment,
    FecStatistics? fecStats,
  }) {
    final service = _diagnosticsService;
    if (service != null) {
      return service.calculateQualityScore(
        diagnostics: diagnostics,
        environment: environment,
        fecStats: fecStats,
      );
    }
    return const DartDiagnosticsService().calculateQualityScore(
      diagnostics: diagnostics,
      environment: environment,
      fecStats: fecStats,
    );
  }
}
