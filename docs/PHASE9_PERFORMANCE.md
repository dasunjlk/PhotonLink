# Phase 9 Performance Benchmarks — Optical Stream

## Encode Throughput (50 iterations, 256-byte data packet)

| Transport | Time (ms) | Notes |
|-----------|-----------|-------|
| Optical Stream (48×48, 3 bpc) | ~43 | Continuous stream codec |
| Color Matrix (24×24, 2 bpc) | ~35 | Discrete color grid |
| QR | ~2 | String PL2 wire |

Optical Stream encode cost is higher than QR (expected — grid rasterization) and comparable to Color Matrix. Throughput advantage comes from **higher default FPS (8 vs 4)** and **larger max file size (4 MB vs 2 MB)**.

## Recovery

- FEC integration reuses Phase 7 `RecoveryEngine` — same recovery success rate as Color Matrix for equivalent redundancy settings
- `OpticalStreamDecoder` duplicate detection reduces reconstruction churn

## Memory / CPU

- Rolling buffer capped at 64 frames
- Camera throttle via adaptive `processingThrottleMs`
- PNG raster generation per emitted frame (sender)

## Test Coverage

```
test/transfer/optical_stream/
  optical_stream_codec_test.dart
  optical_stream_serializer_test.dart
  optical_stream_decoder_sync_test.dart
  optical_stream_loopback_test.dart
  optical_stream_large_transfer_test.dart
  stream_timing_controller_test.dart
test/transfer/benchmarks/optical_stream_benchmark_test.dart
photonlink_core: packet/plos.rs roundtrip test
```

Run: `flutter test test/transfer/optical_stream/`
