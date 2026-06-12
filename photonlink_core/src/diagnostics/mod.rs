use serde::{Deserialize, Serialize};

/// Input for quality score calculation (mirrors Dart FrameDiagnostics + EnvironmentProfile).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QualityScoreInput {
    pub frames_received: u32,
    pub frames_corrupted: u32,
    pub frames_lost: u32,
    pub missing_packet_count: u32,
    pub frames_retried: u32,
    pub detection_accuracy: f64,
    pub avg_brightness: f64,
    pub detection_success_rate: f64,
    pub fec_parity_generated: u32,
    pub fec_recovery_success_rate: f64,
    pub fec_parity_efficiency: f64,
    pub fec_overhead: f64,
}

/// Output quality score with factor breakdown.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QualityScoreOutput {
    pub score: f64,
    pub frame_loss_factor: f64,
    pub decode_error_factor: f64,
    pub retry_factor: f64,
    pub detection_stability_factor: f64,
    pub brightness_factor: f64,
    pub recovery_factor: f64,
}

/// Computes quality score — exact port of Dart QualityScoreCalculator.
pub fn calculate_quality_score(input: &QualityScoreInput) -> QualityScoreOutput {
    let total_frames = input.frames_received + input.frames_corrupted + input.frames_lost;
    let frame_loss_factor = if total_frames == 0 {
        100.0
    } else {
        (1.0
            - (f64::from(input.frames_lost + input.missing_packet_count)
                / f64::from(total_frames + input.missing_packet_count + 1)))
            * 100.0
    };

    let decode_total = input.frames_received + input.frames_corrupted;
    let decode_error_factor = if decode_total == 0 {
        100.0
    } else {
        f64::from(input.frames_received) / f64::from(decode_total) * 100.0
    };

    let retry_factor = if input.frames_retried == 0 {
        100.0
    } else {
        (100.0 - f64::from(input.frames_retried.min(20)) * 3.0).clamp(0.0, 100.0)
    };

    let detection_stability_factor =
        (input.detection_success_rate * 0.6 + input.detection_accuracy * 0.4) * 100.0;

    let brightness = input.avg_brightness;
    let brightness_factor = if brightness < 0.15 || brightness > 0.92 {
        40.0
    } else if brightness < 0.25 || brightness > 0.85 {
        70.0
    } else {
        100.0
    };

    let recovery_factor = recovery_factor(&input);

    let has_fec = input.fec_parity_generated > 0;
    let score = if has_fec {
        (frame_loss_factor * 0.20
            + decode_error_factor * 0.25
            + retry_factor * 0.08
            + detection_stability_factor * 0.22
            + brightness_factor * 0.10
            + recovery_factor * 0.15)
            .clamp(0.0, 100.0)
    } else {
        (frame_loss_factor * 0.25
            + decode_error_factor * 0.30
            + retry_factor * 0.10
            + detection_stability_factor * 0.25
            + brightness_factor * 0.10)
            .clamp(0.0, 100.0)
    };

    QualityScoreOutput {
        score,
        frame_loss_factor: frame_loss_factor.clamp(0.0, 100.0),
        decode_error_factor: decode_error_factor.clamp(0.0, 100.0),
        retry_factor: retry_factor.clamp(0.0, 100.0),
        detection_stability_factor: detection_stability_factor.clamp(0.0, 100.0),
        brightness_factor: brightness_factor.clamp(0.0, 100.0),
        recovery_factor: recovery_factor.clamp(0.0, 100.0),
    }
}

fn recovery_factor(input: &QualityScoreInput) -> f64 {
    if input.fec_parity_generated == 0 {
        return 100.0;
    }
    let success_rate = input.fec_recovery_success_rate * 100.0;
    let efficiency = (input.fec_parity_efficiency * 50.0).clamp(0.0, 50.0);
    let overhead_penalty = (input.fec_overhead * 10.0).clamp(0.0, 30.0);
    (success_rate * 0.6 + efficiency - overhead_penalty).clamp(0.0, 100.0)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn perfect_score_no_fec() {
        let input = QualityScoreInput {
            frames_received: 100,
            frames_corrupted: 0,
            frames_lost: 0,
            missing_packet_count: 0,
            frames_retried: 0,
            detection_accuracy: 1.0,
            avg_brightness: 0.5,
            detection_success_rate: 1.0,
            fec_parity_generated: 0,
            fec_recovery_success_rate: 0.0,
            fec_parity_efficiency: 0.0,
            fec_overhead: 0.0,
        };
        let result = calculate_quality_score(&input);
        assert!((result.score - 100.0).abs() < 0.01);
    }
}
