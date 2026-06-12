# Optical Stream Architecture (Phase 9)

## Overview

Optical Stream is PhotonLink's third transport — a **continuous streaming** mode for high-throughput optical transfer. It reuses the existing protocol stack (compression, encryption, FEC, adaptive engine, reconstruction) without modifying those layers.

## Components

| Component | Path | Role |
|-----------|------|------|
| `OpticalStreamFrame` | `transfer/optical_stream/optical_stream_frame.dart` | Frame type with sync/timestamp fields |
| `OpticalStreamFrameCodec` | `transfer/optical_stream/optical_stream_codec.dart` | Packet ↔ brightness grid codec |
| `OpticalStreamEncoder` | `transfer/optical_stream/optical_stream_encoder.dart` | Continuous cyclic emission |
| `OpticalStreamDecoder` | `transfer/optical_stream/optical_stream_decoder.dart` | Sync, duplicates, rolling buffer |
| `StreamTimingController` | `transfer/optical_stream/stream_timing_controller.dart` | Pacing, jitter, throughput stabilization |
| `OpticalRenderer` / `OpticalDetector` | `transfer/optical_stream/` | Visual encode/decode |
| Controllers | `transfer/application/optical_stream_*_controller.dart` | Session orchestration |

## Sync Strategy

1. **Start-of-stream:** metadata frames + finder patterns until `syncLocked`
2. **Mid-stream resync:** re-acquire grid when detection accuracy drops
3. **Lost-stream recovery:** cyclic re-emission + FEC parity
4. **Clock drift:** per-frame timestamps + timing lanes; `StreamTimingController` stabilizes decode rate

## Timing Model

- Sender: `OpticalStreamEncoder` drives `FrameStreamController` with adaptive FPS from `AdaptiveSessionController`
- Receiver: `StreamTimingController.onDecode()` measures decode FPS; dropped frames slow pacing
- Default stream speed: 8 fps (settings: 2–15 fps)

## Transport Integration

Registered in `transport_registry.dart` as `TransferMethod.opticalStream`.

Reuses:
- `PayloadPipeline` (compress/encrypt/chunk)
- `RecoveryEngine` / `DartFecService` (FEC)
- `AdaptiveSessionController` (quality, FPS, grid)
- `ReconstructionEngine` + `CoreService` (SHA-256 verify)
- Rust `decode_plos_frame` via FRB when backend active

## Future Upgrade Notes

- Higher density: increase `bitsPerCell` (up to 8 levels per cell)
- Multi-stream sessions via `streamId`
- Hardware-timed emission (vs `Timer.periodic`)
- Dedicated `OpticalStreamParameterMapper` for adaptive tiers

## Known Limitations

- Over-the-air camera decode quality depends on display refresh, camera FPS, and lighting
- Windows/web camera pipelines may throttle live analysis
- Binary visual lane is grayscale-only (monochrome theme compatible)
- Default adaptive mapper reuses Color Matrix tier mapping

## Production Readiness

- Loopback-validated encoder/decoder pipeline
- FEC + compression + encryption compatible
- Rust PLOS parser with Dart fallback
- UI: sender visualization, receiver diagnostics panel
- Benchmarks vs QR and Color Matrix in `PHASE9_PERFORMANCE.md`
