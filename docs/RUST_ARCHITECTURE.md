# Rust Architecture Guide (Phase 8)

## Overview

Phase 8 introduces `photonlink_core/`, a Rust workspace containing performance-critical transfer logic. Flutter retains UI, navigation, state management, settings, history, and device permissions.

## Dual-Backend Architecture

```
Controllers → Service Interfaces → backendProvider
                                      ├── dart (default, active)
                                      └── rust (requires toolchain + FRB codegen)
```

Dart backend delegates to existing engines. Rust backend calls `PhotonLinkCoreApi` → FRB → `photonlink_core`.

## Crate Layout

```
photonlink_core/
├── Cargo.toml
├── src/
│   ├── lib.rs              # Module root
│   ├── error.rs            # CoreError + catch_unwind wrapper
│   ├── api/mod.rs          # FRB FFI surface (6 services)
│   ├── hashing/            # SHA-256 hex
│   ├── protocol/           # CRC32 (PLCM)
│   ├── packet/             # PL2 + PLCM codecs
│   │   ├── pl2.rs
│   │   └── plcm.rs
│   ├── chunking/           # Split/merge
│   ├── reconstruction/     # Stateful chunk assembly
│   ├── compression/        # GZip (flate2) + LZ4 (lz4_flex)
│   ├── encryption/         # ChaCha20-Poly1305
│   ├── diagnostics/        # Quality score math
│   └── fec/                # Reed-Solomon erasure coding
│       ├── galois_field.rs
│       ├── reed_solomon.rs
│       └── block_planner.rs
└── tests/                  # Golden vector tests
```

## Module Boundaries

| Rust Module | Dart Service | Stateful? |
|-------------|-------------|-----------|
| `hashing/` | `CoreService` | No |
| `protocol/` | `CoreService` | No |
| `packet/` | `PacketService` | No |
| `chunking/` | via `ChunkingEngine` | No |
| `reconstruction/` | `ReconstructionEngine` | Yes (per session) |
| `compression/` | `CompressionService` | No |
| `encryption/` | `EncryptionService` | No |
| `diagnostics/` | `DiagnosticsService` | No |
| `fec/` | `FecService` | Yes (per session) |

## Compatibility Contracts

All Rust implementations must produce **byte-identical** output to Dart:

- SHA-256: lowercase 64-char hex
- CRC32: reflected IEEE poly `0xEDB88320`
- PL2 wire: `PL2|<type>|<sessionId>|<seq>|<total>|<base64>`
- PLCM binary: magic `PLCM`, big-endian u32 fields, trailing CRC32
- Encryption wire: `nonce(12) + mac(16) + ciphertext`
- FEC: systematic Vandermonde RS over GF(256) primitive `0x11D`

## Error Handling

All FFI entrypoints use `catch_core()` which:
1. Catches Rust panics via `catch_unwind`
2. Maps to `CoreError` enum
3. Returns `Result<T, String>` across the FFI boundary

No `unwrap()` or `panic!` crosses the FFI boundary.

## Dependencies

| Crate | Purpose |
|-------|---------|
| `flutter_rust_bridge` | FFI codegen |
| `sha2` | SHA-256 |
| `flate2` | GZip compression |
| `lz4_flex` | LZ4 compression |
| `chacha20poly1305` | AEAD encryption |
| `serde`/`serde_json` | Serialization |
| `base64` | PL2 payload encoding |
| `zeroize` | Key material cleanup |
| `thiserror` | Error types |

## Build

```bash
cd photonlink_core
cargo test
cargo build --release
```

## Flutter Integration

```bash
cd photonlink_app
flutter_rust_bridge_codegen generate
flutter pub get
flutter test
```

Switch backend in `core_providers.dart`:
```dart
final backendProvider = Provider<CoreBackend>(
  (ref) => CoreBackend.rust,  // after toolchain setup
);
```
