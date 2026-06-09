# Phase 6 Performance Summary

## Adaptive Engine Overhead

Benchmark: `test/transfer/benchmarks/adaptive_overhead_benchmark_test.dart`

| Metric | Result (target) |
|--------|-------------------|
| 1000 evaluate cycles | < 500 ms total |
| Per-cycle average | < 0.5 ms |
| Memory | Stateless calculators; rolling windows capped at 30–200 samples |
| Decision frequency | Cooldown 3–8 s; hysteresis 3–8 samples |

## Impact on Throughput

- **Sender FPS reschedule**: Timer restart only when tier changes (infrequent).
- **Receiver brightness sample**: Subsampled Y-plane (~256 samples/frame).
- **Environment analyzer**: O(windowSize) per frame; window ≤ 30.
- **Quality score**: Pure arithmetic; no I/O.

## CPU / Memory Notes

- `device_info_plus` queried once per session start.
- `AdaptationDiagnostics` caps history at 200 entries.
- No background isolates; all work on main isolate between camera frames.

## Stability Design

- Single-step tier changes (no multi-level jumps).
- Cooldown prevents parameter churn.
- Hysteresis prevents oscillation on borderline scores.
- Profile override available for manual stability.

## Verification

```powershell
cd photonlink_app
flutter test
flutter analyze
```
