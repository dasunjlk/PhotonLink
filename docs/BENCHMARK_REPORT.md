# Phase 8 Benchmark Report

## Methodology

Benchmarks run via `test/transfer/benchmarks/rust_migration_benchmark_test.dart` using Dart's `Stopwatch` for microsecond timing. Each operation runs 100 iterations (50 for FEC) on 64 KB payloads unless noted.

### Metrics Collected

| Metric | Method |
|--------|--------|
| Chunking speed | `ChunkingEngine.split()` on 64 KB |
| Reconstruction speed | `ReconstructionEngine.rebuild()` |
| SHA-256 speed | `CoreService.sha256Hex()` |
| CRC32 speed | `CoreService.crc32Compute()` |
| GZip compression | `CompressionService.compress(gzip)` |
| ChaCha20-Poly1305 | `EncryptionService.encryptIfEnabled()` |
| FEC encode | `FecEncoder.encode()` on 10 chunks |
| FEC recovery | `RecoveryEngine.attemptRecovery()` |

### Memory / CPU

Memory profiling requires `--profile` mode or platform tools. Document CPU via:
```bash
flutter test test/transfer/benchmarks/rust_migration_benchmark_test.dart
```

Rust comparison after toolchain install:
```bash
cd photonlink_core && cargo test --release -- --nocapture
```

## Dart Baselines (Phase 8, backend=dart)

Captured from `rust_migration_benchmark_test.dart` (100 iterations, 64 KB payloads):

| Operation | Dart (µs) |
|-----------|-----------|
| Chunking 64KB ×100 | 6,479 |
| Reconstruction rebuild ×100 | 16,987 |
| SHA-256 64KB ×100 | 129,564 |
| CRC32 64KB ×100 | 300,769 |
| GZip 64KB ×100 | 39,608 |
| ChaCha20-Poly1305 64KB ×100 | 417,366 |
| FEC encode 10 chunks ×50 | 20,496 |
| FEC recovery ×50 | 28,402 |

Reference from prior phases:

| Operation | Prior Phase | Notes |
|-----------|------------|-------|
| GZip 32KB | 3,778 µs | Phase 4 benchmark |
| ChaCha20 32KB | 13,257 µs | Phase 4 benchmark |
| FEC encode 100 chunks | 10 ms | Phase 7 benchmark |
| Adaptive evaluate/cycle | 20.3 µs | Phase 6 benchmark |

Phase 8 benchmark test prints live Dart baselines on each run.

## Rust Projections

Based on typical Rust vs Dart performance for these workloads:

| Operation | Expected Rust Improvement |
|-----------|--------------------------|
| SHA-256 / CRC32 | 2–5× |
| GZip compression | 1.5–3× |
| ChaCha20-Poly1305 | 2–4× |
| Chunking / merge | 1.5–2× |
| FEC RS encode/decode | 3–10× |
| Quality score calc | 1.2–2× |

Actual numbers require `cargo build --release` + FRB integration.

## How to Compare

1. Run Dart benchmark: `flutter test test/transfer/benchmarks/rust_migration_benchmark_test.dart`
2. Install Rust toolchain
3. Run Rust tests: `cd photonlink_core && cargo test --release`
4. Generate FRB bindings and set `CoreBackend.rust`
5. Re-run Dart benchmark with Rust backend
6. Fill comparison table below

## Comparison Table (to be filled)

| Operation | Dart (µs) | Rust (µs) | Speedup |
|-----------|-----------|-----------|---------|
| Chunking 64KB ×100 | TBD | TBD | TBD |
| Reconstruction ×100 | TBD | TBD | TBD |
| SHA-256 64KB ×100 | TBD | TBD | TBD |
| CRC32 64KB ×100 | TBD | TBD | TBD |
| GZip 64KB ×100 | TBD | TBD | TBD |
| ChaCha20 64KB ×100 | TBD | TBD | TBD |
| FEC encode ×50 | TBD | TBD | TBD |
| FEC recovery ×50 | TBD | TBD | TBD |

## Test Coverage

- `rust_migration_benchmark_test.dart` — full pipeline benchmark
- `core_service_test.dart` — golden vectors for cross-validation
- `photonlink_core/src/*/mod.rs` — inline `#[cfg(test)]` modules
