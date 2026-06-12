# PhotonLink Core (Rust)

Phase 8 Rust workspace — performance-critical transfer logic.

## Location

This crate supersedes the Phase 1 stub at `native/photonlink_core/`.

## Build

Requires Rust >= 1.70 and `flutter_rust_bridge_codegen`:

```bash
cd photonlink_core
cargo test
cargo build --release
```

## Flutter integration

From `photonlink_app/`:

```bash
flutter_rust_bridge_codegen generate
flutter pub get
flutter test
```

## Modules

| Module | Purpose |
|--------|---------|
| `hashing/` | SHA-256 hex |
| `protocol/` | CRC32 (PLCM) |
| `packet/` | PL2 + PLCM codecs |
| `chunking/` | Split/merge |
| `reconstruction/` | Chunk assembly |
| `compression/` | GZip + LZ4 |
| `encryption/` | ChaCha20-Poly1305 |
| `diagnostics/` | Quality score math |
| `fec/` | Reed-Solomon erasure coding |
| `api/` | FRB FFI surface |
