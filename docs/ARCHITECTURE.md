# PhotonLink Architecture

## Overview

PhotonLink is an offline peer-to-peer file transfer platform using optical communication. **Phase 5** adds Color Matrix Transport alongside QR, with a transport-agnostic protocol stack (compression, encryption, reliability, diagnostics).

## Layer Diagram

```
┌──────────────────────────────────────────────────────────┐
│  features/  home · transfer_setup · qr_transfer ·        │
│             color_matrix_transfer · camera_scan · about    │
├──────────────────────────────────────────────────────────┤
│  transfer/  core (chunking, reconstruction, pipeline)    │
│             compression · encryption · reliability         │
│             diagnostics · qr/ · color_matrix/            │
│             application (Riverpod family controllers)    │
├──────────────────────────────────────────────────────────┤
│  protocols/ interfaces + transport_registry              │
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
| `FrameStreamController<T>` | Cyclic frame emission |

### Registered Transports

| Method | Frame Type | Module |
|--------|-----------|--------|
| `qr` | `String` (PL2 wire) | `transfer/qr/` |
| `colorMatrix` | `ColorMatrixFrame` | `transfer/color_matrix/` |

## Protocol Stack (Transport-Agnostic)

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

| Layer | Path | Notes |
|-------|------|-------|
| Compression | `transfer/compression/` | none, gzip |
| Encryption | `transfer/encryption/` | none, ChaCha20-Poly1305 |
| Payload pipeline | `transfer/core/payload_pipeline.dart` | compress→encrypt / reverse |
| Reliability | `transfer/reliability/` | missing packets, retry, recovery |
| Diagnostics | `transfer/diagnostics/` | frames, throughput, decode time |
| History | `history/` | per-method transfer records |

## QR Transfer (unchanged wire format)

```
PL2|<type>|<sessionId>|<seq>|<total>|<base64Payload>
```

Metadata JSON now includes optional `compression`, `encryption`, `transformedSize`, `kdfSalt` fields (backward compatible).

## Color Matrix Transfer

See [COLOR_MATRIX_FORMAT.md](COLOR_MATRIX_FORMAT.md).

- PLCM v1 binary frames encoded as RGB cells
- Configurable grid: 16×16, 24×24, 32×32
- Orientation markers + sync border
- Camera image-stream decoding

## Controllers

Family providers parameterized by `TransferMethod`:

- `senderControllerProvider(TransferMethod)`
- `receiverControllerProvider(TransferMethod)`

## Routes

| Route | Screen |
|-------|--------|
| `/qr/send`, `/qr/receive` | QR transfer |
| `/color-matrix/send`, `/color-matrix/receive` | Color Matrix transfer |
| `/settings` | Color Matrix + compression/encryption settings |

## Test Coverage (Phase 5)

38 tests: chunking, QR codec, reconstruction, compression, encryption, reliability, color matrix encode/decode/generation/detection, widget smoke tests.

Run: `cd photonlink_app && flutter test`

## Future Transports

`Transport<T>` abstraction supports `opticalStream`, `audio`, `flash` without changing the protocol stack.
