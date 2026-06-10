# PhotonLink Architecture

## Overview

PhotonLink is an offline peer-to-peer file transfer platform using optical communication (QR codes, color matrices). **Phase 4** adds compression, encryption, scheduling, and throughput monitoring on the reliable bidirectional QR transport. **Phase 5** adds **Color Matrix** as a second registered transport via a transport-agnostic protocol stack. **Phase 6** adds the **Adaptive Optical Engine** for capability/environment-aware parameter tuning. **Phase 7** adds **Forward Error Correction** (Reed-Solomon parity packets) for loss recovery without retransmission.

## Layer Diagram

```
┌──────────────────────────────────────────────────────────┐
│  features/  home · transfer_setup · qr_transfer ·        │
│             color_matrix_transfer · settings · history   │
├──────────────────────────────────────────────────────────┤
│  transfer/  core (chunking, payload pipeline, integrity) │
│             compression · encryption · security          │
│             scheduler · metrics · reliability          │
│             qr/ · color_matrix/ · adaptive/ · fec/ · diagnostics/ │
│             application (Riverpod controllers)         │
├──────────────────────────────────────────────────────────┤
│  protocols/ interfaces + transport_registry + impl       │
│  settings/  │  history/  │  shared/widgets/  │  ui/     │
├──────────────────────────────────────────────────────────┤
│  core/  bootstrap · router · theme · constants · errors  │
└──────────────────────────────────────────────────────────┘
```

## Transport Abstraction

| Component | Role |
|-----------|------|
| `TransferMethod` | Transport type enum (`qr`, `colorMatrix`, …) |
| `Transport<TFrame>` | Codec + limits + capabilities bundle |
| `TransportRegistry` | DI registry consumed by controllers |
| `TransferEncoder<T>` / `TransferDecoder<T>` | Packet ↔ frame encoding |
| `TransportLimitsResolver<T>` | Chunk sizing and frame capacity |
| `FrameStreamController<T>` | Cyclic frame emission (Color Matrix sender) |

### Registered Transports

| Method | Frame Type | Module |
|--------|-----------|--------|
| `qr` | `String` (PL2 wire) | `transfer/qr/` |
| `colorMatrix` | `ColorMatrixFrame` | `transfer/color_matrix/` |

## Efficiency Pipeline (Phase 4)

```mermaid
flowchart LR
  File[File bytes] --> Pipeline[PayloadPipeline]
  Pipeline --> Chunk[ChunkingEngine]
  Chunk --> Packets[TransferPacket]
  Packets --> Codec[Transport Codec]
  Codec --> Display[QR / Color Matrix]
  Display -.-> Camera[Receiver Camera]
  Camera --> Decode[Transport Decoder]
  Decode --> Recon[ReconstructionEngine]
  Recon --> Pipeline2[Reverse Pipeline]
  Pipeline2 --> Verify[SHA-256 Integrity]
```

| Module | Path | Role |
|--------|------|------|
| CompressionManager | `transfer/compression/` | GZip active; LZ4 placeholder |
| EncryptionManager | `transfer/encryption/` | ChaCha20-Poly1305 AEAD |
| PayloadPipeline | `transfer/core/payload_pipeline.dart` | compress→encrypt / reverse |
| TransferScheduler | `transfer/scheduler/` | Normal vs performance FPS (QR) |
| ThroughputMonitor | `transfer/metrics/` | Bytes/sec, compression ratio |

## QR Transfer (Phase 3/4)

Bidirectional round-based protocol with ACK/NAK recovery. Controllers: `senderControllerProvider`, `receiverControllerProvider` using `ReliableTransferContext`.

Wire format: `PL2|<type>|<sessionId>|<seq>|<total>|<base64Payload>`

Packet types: `MetadataPacket`, `DataPacket`, `SessionSetupPacket`, `AckPacket`, `NakPacket`, `HandshakePacket`, `ControlPacket`.

When encryption is enabled, sender shows a **setup QR** first; receiver scans it before metadata.

See [SECURITY.md](SECURITY.md) and [PHASE4_BENCHMARKS.md](PHASE4_BENCHMARKS.md).

## Color Matrix Transfer (Phase 5)

- PLCM v1 binary frames encoded as RGB cells
- Configurable grid: 16×16, 24×24, 32×32
- Orientation markers + sync border; camera image-stream decoding
- Cyclic one-way broadcast (no ACK/NAK feedback)
- Session key embedded in metadata JSON when encryption is enabled

Controllers: `colorMatrixSenderControllerProvider`, `colorMatrixReceiverControllerProvider`.

See [COLOR_MATRIX_FORMAT.md](COLOR_MATRIX_FORMAT.md).

## Adaptive Optical Engine (Phase 6)

Transport-agnostic adaptation layer in `transfer/adaptive/`:

- `DeviceCapabilityDetector` — device/display/camera capability profile
- `EnvironmentAnalyzer` — brightness, detection, decode, loss rates
- `QualityScoreCalculator` — 0–100 quality score
- `AdaptationEngine` — cooldown + hysteresis tier adjustments
- `ColorMatrixParameterMapper` — tiers → grid size / fps / density

Integrated into Color Matrix sender (session params + live FPS) and receiver (cadence, lighting hints, analytics). Settings: adaptive mode, aggressiveness, profile override, quality monitoring.

See [ADAPTIVE_ENGINE.md](ADAPTIVE_ENGINE.md) and [PHASE6_PERFORMANCE.md](PHASE6_PERFORMANCE.md).

## Controllers

| Provider | Transport | Flow |
|----------|-----------|------|
| `senderControllerProvider` | QR | Round-based bidirectional |
| `receiverControllerProvider` | QR | Round-based bidirectional |
| `colorMatrixSenderControllerProvider` | Color Matrix | Cyclic frame stream |
| `colorMatrixReceiverControllerProvider` | Color Matrix | Camera decode → reconstruct |

## Forward Error Correction (Phase 7)

Transport-independent FEC layer in `transfer/fec/`:

| Component | Role |
|-----------|------|
| `FecEncoder` / `FecDecoder` | Reed-Solomon parity generation and recovery |
| `RecoveryEngine` | Orchestrates recovery; falls back to NAK/retry (QR) |
| `ParityPacket` | New sealed packet type (PL2 `P`, PLCM type 2) |
| `ErasureCode` | Interface for future Fountain codes |

See [FEC_ARCHITECTURE.md](FEC_ARCHITECTURE.md) and [PHASE7_PERFORMANCE.md](PHASE7_PERFORMANCE.md).

## State Machine

`lib/transfer/state/transfer_phase.dart` — 13 phases including `awaitingAcknowledgements`, `recoveringMissingPackets`, `reconstructing`. QR controllers enforce transitions via `TransferStateMachine`. Color Matrix controllers use a subset of phases.

## Routes

| Route | Screen |
|-------|--------|
| `/qr/send`, `/qr/receive`, `/qr/complete` | QR transfer |
| `/color-matrix/send`, `/color-matrix/receive`, `/color-matrix/complete` | Color Matrix |
| `/settings`, `/history`, `/analytics` | Settings, History, Live analytics |

## Test Coverage

Run: `cd photonlink_app && flutter test`

Includes Phase 3–7 tests: QR reliability, compression, encryption, adaptive engine, FEC (13+ tests), Color Matrix encode/decode. **100 automated tests** total.

## Future Transports

`Transport<T>` abstraction supports `opticalStream`, `audio`, `flash` without changing the core pipeline. Adaptive engine and FEC layers are reusable by future transports. See [PHASE8_READINESS.md](PHASE8_READINESS.md).
