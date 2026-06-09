import 'adaptive_parameters.dart';

/// Result of a single adaptation evaluation cycle.
class AdaptationDecision {
  const AdaptationDecision({
    required this.applied,
    required this.previous,
    required this.current,
    this.reason = '',
    this.timestamp,
  });

  final bool applied;
  final AdaptiveParameters previous;
  final AdaptiveParameters current;
  final String reason;
  final DateTime? timestamp;

  static AdaptationDecision noChange(AdaptiveParameters params) {
    return AdaptationDecision(
      applied: false,
      previous: params,
      current: params,
    );
  }
}

/// Record of a parameter change for diagnostics/history.
class AdaptiveEvent {
  const AdaptiveEvent({
    required this.timestamp,
    required this.parameter,
    required this.fromValue,
    required this.toValue,
    required this.reason,
  });

  final DateTime timestamp;
  final String parameter;
  final String fromValue;
  final String toValue;
  final String reason;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'parameter': parameter,
        'fromValue': fromValue,
        'toValue': toValue,
        'reason': reason,
      };

  factory AdaptiveEvent.fromJson(Map<String, dynamic> json) {
    return AdaptiveEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      parameter: json['parameter'] as String,
      fromValue: json['fromValue'] as String,
      toValue: json['toValue'] as String,
      reason: json['reason'] as String,
    );
  }
}
