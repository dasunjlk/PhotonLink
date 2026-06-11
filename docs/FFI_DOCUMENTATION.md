# FFI Documentation (Phase 8)

## Bridge Technology

PhotonLink uses [flutter_rust_bridge](https://candid.dev/flutter_rust_bridge) v2 for Dart ↔ Rust communication.

## Configuration

[`photonlink_app/flutter_rust_bridge.yaml`](../photonlink_app/flutter_rust_bridge.yaml):

```yaml
rust_input: crate::api
rust_root: ../photonlink_core/
dart_output: lib/src/rust
dart_entrypoint_class_name: PhotonLinkCoreApi
web: false
```

## Service Interfaces (Dart)

Flutter communicates only through these stable interfaces in `lib/services/core/`:

| Interface | Methods |
|-----------|---------|
| `CoreService` | `sha256Hex`, `sha256Verify`, `crc32Compute`, `crc32Validate` |
| `CompressionService` | `compress`, `decompress` |
| `EncryptionService` | `encryptIfEnabled`, `decryptIfEnabled` |
| `PacketService` | `encodePl2Frame`, `decodePl2Frame`, `serializePlcmFrame`, `deserializePlcmFrame` |
| `FecService` | `configure`, `generateParity`, `ingestParity`, `attemptRecovery` |
| `DiagnosticsService` | `calculateQualityScore` |

## Abstract API Layer

`PhotonLinkCoreApi` (`lib/services/core/photon_link_core_api.dart`) is the Dart-side abstract interface mirroring Rust FFI functions. Implementations:

| Class | When Used |
|-------|-----------|
| `NotConnectedCoreApi` | Default — throws if Rust backend selected without codegen |
| `FrbCoreApi` | After `flutter_rust_bridge_codegen generate` (not yet generated) |

## Rust FFI Functions

Defined in `photonlink_core/src/api/mod.rs`:

### CoreService
- `core_version() -> String`
- `sha256_hex(data) -> String`
- `sha256_verify(data, expected) -> bool`
- `crc32_compute(data) -> u32`
- `crc32_validate(data, expected) -> bool`

### PacketService
- `encode_pl2_data_frame(session_id, chunk_id, total, payload) -> String`
- `decode_pl2_frame(raw) -> Pl2FrameDto`
- `encode_plcm_frame(frame) -> Vec<u8>`
- `decode_plcm_frame(bytes) -> PlcmFrameDto`

### Chunking
- `chunk_split(data, session_id, chunk_size) -> Vec<DataChunkDto>`
- `chunk_merge(chunks) -> Vec<u8>`

### CompressionService
- `compress_data(input, kind) -> CompressionOutputDto`
- `decompress_data(input, kind, original_size) -> CompressionOutputDto`

### EncryptionService
- `encrypt_data(plaintext, session_key) -> Vec<u8>`
- `decrypt_data(wire, session_key) -> Vec<u8>`

### DiagnosticsService
- `calculate_quality_score(input) -> QualityScoreOutput`

### FecService
- `fec_encode_block(data_symbols, parity_count, symbol_length) -> Vec<Vec<u8>>`
- `fec_decode_block(data_count, parity_count, symbol_length, erasures, available) -> Option<Vec<Vec<u8>>>`

## DTO Types

Serializable structs cross the FFI boundary:
- `Pl2FrameDto`, `PlcmFrameDto`, `DataChunkDto`
- `CompressionOutputDto`
- `QualityScoreInput` / `QualityScoreOutput`
- `ReconstructionHandle` (opaque, stateful)

## Codegen Workflow

```bash
# 1. Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 2. Install FRB codegen
cargo install flutter_rust_bridge_codegen

# 3. Generate bindings
cd photonlink_app
flutter_rust_bridge_codegen generate

# 4. Build Rust
cd ../photonlink_core
cargo build --release

# 5. Wire FrbCoreApi adapter (single file importing generated code)
# 6. Override photonLinkCoreApiProvider in bootstrap.dart
# 7. Set backendProvider to CoreBackend.rust
```

## Error Propagation

Rust errors map to Dart `String` messages via `CoreError`:
- `InvalidInput` — bad parameters
- `ChecksumMismatch` — PLCM CRC failure
- `DecodeFailed` — packet parse failure
- `CompressionFailed` / `EncryptionFailed` / `RecoveryFailed`
- `InternalPanic` — caught Rust panic

## Memory Safety

- Session keys passed as `Vec<u8>`, zeroized after use in Rust encryption module
- No raw pointer exposure to Dart
- `ReconstructionHandle` is opaque — Dart cannot access internal maps directly
