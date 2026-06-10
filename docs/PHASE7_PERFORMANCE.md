# Phase 7 Performance Summary

## FEC Benchmark Results (Automated)

Run: `flutter test test/transfer/benchmarks/fec_benchmark_test.dart`

| Metric | Typical Value (100 chunks, 256 B, 10% redundancy) |
|--------|-----------------------------------------------------|
| Parity packets generated | ~10 |
| Encode time | < 5000 ms (Dart, debug) |
| Overhead ratio | ~0.10 (parity/data) |
| Recovery success (1-2 losses/block) | High with balanced profile |

## Throughput Impact

- **Sender**: Additional parity frames increase total broadcast size by redundancy%.
- **QR**: Parity sent once on first full round; reduces NAK/retry rounds when losses are recoverable.
- **Color Matrix**: Parity appended to cyclic stream; receiver recovers across loops.

## CPU / Memory

- RS encode: O(m × k × symbolLength) per block per byte position.
- RS decode: O(k³ × symbolLength) Gaussian elimination per block.
- Pure Dart implementation; suitable for mobile; Rust migration deferred to future phases.

## Parity Efficiency

`parityEfficiency = packetsRecovered / parityConsumed`

Tracked in `FecStatistics` and surfaced in diagnostics, quality score, and history v5.

## Test Coverage Summary

| Area | Tests |
|------|-------|
| GF(256) arithmetic | `fec_core_test.dart` |
| RS encode/decode | `fec_core_test.dart` |
| Parity generation/consumption | `fec_core_test.dart`, `fec_integration_test.dart` |
| RecoveryEngine | `fec_integration_test.dart` |
| QR/Color Matrix parity codec | `fec_integration_test.dart` |
| Adaptive FEC policy | `fec_integration_test.dart` |
| Quality score FEC factor | `fec_integration_test.dart` |
| History v5 FEC fields | `history_v5_test.dart` |
| Benchmark | `fec_benchmark_test.dart` |

Total FEC tests: **13+** (plus full suite regression).
