# Future Expansion Notes (Post Phase 8)

## Immediate Next Steps

1. **Install Rust toolchain** and run `cargo test --release` in `photonlink_core/`
2. **Generate FRB bindings** via `flutter_rust_bridge_codegen generate`
3. **Create `FrbCoreApi` adapter** implementing `PhotonLinkCoreApi`
4. **Flip `backendProvider`** to `CoreBackend.rust` after validation
5. **Fill benchmark comparison table** in `BENCHMARK_REPORT.md`

## Phase 9 Candidates

### Fountain Codes (LT / Raptor / RaptorQ)
- `FecCodecType` enum already reserves `ltCodes`, `raptor`, `raptorQ`
- `ErasureCode` interface in Dart; add Rust implementations in `fec/`
- New block planner for rateless codes

### Optical Stream Transfer
- Rust module: `stream/` for continuous frame encoding
- Real-time FEC with sliding window
- GPU-accelerated color matrix encoding (see below)

### GPU Acceleration
- `wgpu` or platform-specific compute shaders for:
  - Color matrix rasterization
  - Batch QR frame generation
  - Parallel FEC matrix operations over GF(256)

### Audio Transfer
- Rust module: `audio/` for FSK/modulation encoding
- Separate from optical pipeline

### Machine Learning
- On-device quality prediction model (TFLite or ONNX via Rust)
- Feed into adaptive engine as additional quality factor

## Architecture Extensions

### Additional Rust Modules
```
photonlink_core/src/
├── stream/          # Optical stream encoding
├── gpu/             # GPU compute kernels
├── audio/           # Audio modulation
└── ml/              # Quality prediction
```

### Platform Integration
- iOS: build Rust as `.a` static lib via `cargo-lipo`
- Android: build as `.so` via `cargo-ndk`
- Desktop: direct `cdylib` loading

### WebAssembly
- `flutter_rust_bridge.yaml` has `web: false`
- Future: compile to WASM for web preview builds

## LZ4 Activation

Rust implements real LZ4 via `lz4_flex`. To enable in Dart path:
1. Activate Rust backend, OR
2. Add `lz4` Dart package and enable `Lz4CompressionStrategy`

## Settings UI

Future setting: "Performance Engine" toggle (Dart / Rust) in Settings screen, wired to `backendProvider`.

## CI/CD

Add to CI pipeline:
```yaml
- rust: cargo test --release
- frb: flutter_rust_bridge_codegen generate --verify
- cross: flutter test (dart backend)
- cross: flutter test (rust backend, if toolchain available)
```

## Monitoring

When Rust backend is active:
- Expose `core_version()` in About screen
- Log backend selection at bootstrap
- Track Rust vs Dart error rates in diagnostics
