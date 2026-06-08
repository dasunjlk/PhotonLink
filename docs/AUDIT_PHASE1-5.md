# PhotonLink Phase 1–5 Audit Report

**Date:** June 2026  
**Branch audited:** `color-matrix` (merged with `development`)  
**Sources:** Agent transcripts (original phase briefs), `docs/`, `photonlink_app/lib/`, `photonlink_app/test/`

---

## Executive Summary

| Phase | Verdict | Summary |
|-------|---------|---------|
| **Phase 1** | **Delivered** | Scaffold, UI, settings/history shells, camera preview, protocol interfaces, Rust skeleton |
| **Phase 2** | **Delivered** | QR MVP: chunking, PL2 codec, cyclic streaming, reconstruction, SHA-256, history |
| **Phase 3** | **Delivered** | Bidirectional ACK/NAK, retry, resume/persistence, 13-phase state machine, diagnostics |
| **Phase 4** | **Partial** | Compression (GZip not LZ4), encryption, pipeline, scheduler, throughput — delivered; LZ4 deferred |
| **Phase 5** | **Partial** | Color Matrix transport MVP delivered; planned ACK/NAK reuse **not** implemented (one-way broadcast) |

**Overall:** Phases 1–3 are solid. Phase 4 and 5 shipped with intentional deviations. Post-merge integration is functional (58 tests passing) but has architecture debt, security gaps on the Color Matrix path, and documentation drift.

---

## Phase 1 — Foundation Scaffold

### Intended (transcript `f80e9032`)

- Folder architecture (`core/`, `features/`, `protocols/`, `settings/`, `history/`, `ui/`)
- Animated home screen with transfer method cards
- Settings, history UI (mock), camera preview (no decode), file picker prototype
- Protocol abstraction interfaces (no implementations)
- Placeholder Color Matrix / Optical Stream stubs
- Rust skeleton at `native/photonlink_core/` (not wired)

### Delivered

| Item | Status | Evidence |
|------|--------|----------|
| Folder structure | Yes | `photonlink_app/lib/` layout |
| Home + routing | Yes | `features/home/`, `core/router/app_router.dart` |
| Settings persistence | Yes | `settings/` module |
| History persistence | Yes | `history/data/persistent_history_repository.dart` (evolved beyond mock) |
| Camera preview | Yes | `features/camera_scan/` |
| Protocol interfaces | Yes | `protocols/interfaces/` |
| Rust skeleton | Yes | `native/photonlink_core/` — stub only |
| Stubs | Partial | `protocols/impl/*` still throw `UnimplementedError`; real Color Matrix is in `transfer/color_matrix/` |

### Gaps

- `docs/SETUP.md` still lists Phase 1 limitations (mock history, no transfer) — **obsolete**
- `photonlink_app/README.md` is default Flutter boilerplate — **stale**

---

## Phase 2 — QR Optical File Transfer MVP

### Intended

- Offline QR file transfer for `txt`, `pdf`, `jpg`, `png`, `zip`
- Metadata + chunked data packets, PL2 wire format
- Cyclic QR streaming, reconstruction, SHA-256 integrity
- Sender/receiver UI, session persistence prep, history records
- Transport-agnostic core reusable by future transports

### Delivered

| Item | Status | Evidence |
|------|--------|----------|
| File types + limits | Yes | `integrity_verifier.dart`, `transfer_limits.dart` |
| Chunking | Yes | `chunking_engine.dart` |
| PL2 codec | Yes | `qr_frame_codec.dart` |
| Cyclic stream | Yes | `qr_stream_controller.dart` |
| Reconstruction | Yes | `reconstruction_engine.dart` |
| Integrity | Yes | `integrity_verifier.dart` |
| UI | Yes | `features/qr_transfer/` |
| History | Yes | `history/` module |
| Tests | Yes | `qr_codec_test.dart`, `reconstruction_test.dart`, etc. |

### Gaps

- None critical for Phase 2 scope; evolved into Phase 3/4 on same QR path.

---

## Phase 3 — Reliable QR Transport

### Intended

- ACK/NAK, missing packet tracker, retry manager, session recovery/resume
- 13-phase state machine with role guards
- Diagnostics collector + UI metrics
- History v2 fields (session ID, duration, retries, failure reason)
- Transport-agnostic reliability interfaces

### Delivered

| Item | Status | Evidence |
|------|--------|----------|
| ACK/NAK | Yes | `acknowledgement_manager_impl.dart`, PL2 types A/N/H/C |
| Missing packets | Yes | `missing_packet_tracker_impl.dart` |
| Retry | Yes | `retry_manager_impl.dart`, `retry_policy.dart` |
| Resume/persistence | Yes | `session_persistence_manager_impl.dart`, `received_chunk_store.dart` |
| State machine | Yes | `transfer_state_machine.dart`, 13 phases |
| Diagnostics | Yes | `diagnostics_collector_impl.dart`, `diagnostics_panel.dart` |
| Controllers | Yes | `sender_controller.dart`, `receiver_controller.dart`, `reliable_transfer_context.dart` |
| Tests | Yes | `ack_manager_test.dart`, `nak_tracker_test.dart`, `state_machine_test.dart`, `resume_recovery_test.dart` |

### Gaps

- Resume integration test is in-memory only; disk persistence not tested end-to-end.
- `ReliableTransferContext` instantiates managers directly — Riverpod providers for same types are unused.

---

## Phase 4 — Efficiency & Security

### Intended

- Compression (planned LZ4), encryption (ChaCha20-Poly1305), payload pipeline
- Session key exchange (setup QR), transfer scheduler, throughput monitor
- Settings for compression/encryption/mode/diagnostics
- Security review doc, benchmarks

### Delivered

| Item | Status | Evidence |
|------|--------|----------|
| Compression | **GZip** (not LZ4) | `gzip_compression_strategy.dart`; LZ4 is disabled placeholder |
| Encryption | Yes | `chacha20_encryption_strategy.dart` |
| Payload pipeline | Yes | `payload_pipeline.dart` |
| Key exchange | Simplified | `session_key_exchange.dart` — random 256-bit key in setup QR (no ECDH) |
| Scheduler | Yes | `transfer_scheduler.dart`, `transfer_mode.dart` |
| Throughput | Yes | `throughput_monitor.dart` |
| Settings UI | Yes | `settings_screen.dart` |
| Security doc | Yes | `docs/SECURITY.md` |
| Benchmarks | Yes | `docs/PHASE4_BENCHMARKS.md`, `phase4_benchmark_test.dart` |

### Deviations

| Planned | Shipped | Reason |
|---------|---------|--------|
| LZ4 compression | GZip active, LZ4 placeholder | Rust FFI not wired (`lz4_compression_strategy.dart:5`) |
| ECDH key exchange | Random key in setup QR | Documented limitation in `SECURITY.md` |

---

## Phase 5 — Color Matrix Transport

### Intended

- Second transport via `Transport<T>` registry; QR unchanged
- PLCM v1 frame format, encoder/decoder, generator, detector, camera pipeline
- **Reuse Phase 3 reliability** (ACK/NAK, retry, resume) and Phase 4 transforms
- Settings for grid size, frame rate, quality, debug overlay
- Sender/receiver/completion UI, diagnostics, tests, format docs

### Delivered

| Item | Status | Evidence |
|------|--------|----------|
| Transport abstraction | Yes | `transport_registry.dart`, `Transport<T>`, `FrameStreamController<T>` |
| PLCM codec | Yes | `color_matrix_frame_codec.dart`, `color_matrix_serializer.dart` |
| Generator/detector | Yes | `color_frame_generator.dart`, `color_frame_detector.dart` |
| Camera pipeline | Yes | `color_matrix_receiver_screen.dart` image stream |
| Dedicated controllers | Yes | `color_matrix_sender_controller.dart`, `color_matrix_receiver_controller.dart` |
| Compression/encryption | Yes | Uses `PayloadPipeline` (Phase 4 stack) |
| Settings (partial) | Partial | Grid size API exists; frame rate on sender slider, not all settings in UI |
| UI routes | Yes | `/color-matrix/send`, `/receive`, `/complete` |
| Tests | Partial | Codec, encoder, generation, corrupted, large chunk sizing — no controller tests |
| Docs | Partial | `COLOR_MATRIX_FORMAT.md`, `PHASE5_PERFORMANCE.md`, `PHASE6_READINESS.md` |

### Deviations

| Planned | Shipped | Impact |
|---------|---------|--------|
| ACK/NAK reliability on Color Matrix | One-way cyclic broadcast | `supportsReliabilityFeedback: false` in `color_matrix_transport.dart` |
| Same integrity gates as QR | Color Matrix receiver weaker | See Security section |
| 2 MB file limit enforced | 512 KB enforced at runtime | `validateFileSize` used `maxFileBytes` alias for QR only |

---

## Architecture & Code Quality

### Active path (correct)

```
features/* → transfer/application/*_controller → transport_registry → transfer/{qr,color_matrix}/
```

### Dead / parallel layer

| Artifact | Issue |
|----------|-------|
| `protocols/protocol_registry.dart` | Never imported outside itself |
| `protocols/impl/qr_protocol.dart` | Only referenced by dead registry |
| `protocols/impl/color_matrix_protocol.dart` | `UnimplementedError` stub |
| `protocols/impl/optical_stream_protocol.dart` | `UnimplementedError` stub |
| `transfer/core/session_store.dart` | Superseded by `SessionPersistenceManagerImpl`; no references |
| `transfer/metrics/performance_diagnostics.dart` | No consumers |
| `protocols/interfaces/reliability/retry_policy.dart` | Duplicate of `transfer/reliability/models/retry_policy.dart`; unused |
| `qrTransportProvider` | Declared, never read |

### Duplicate type names

| Name | Location A | Location B |
|------|------------|------------|
| `TransferDiagnostics` | `protocols/interfaces/reliability/` (frame metrics) | `transfer/reliability/models/` (packet metrics) |
| `DiagnosticsCollector` | Interface in `protocols/interfaces/reliability/` | Concrete class in `transfer/diagnostics/` |
| `RetryPolicy` | `protocols/interfaces/reliability/retry_policy.dart` | `transfer/reliability/models/retry_policy.dart` |

### Unused Riverpod providers

Declared in `transfer_providers.dart` but never `ref.read`/`watch`:

- `missingPacketTrackerProvider`, `acknowledgementManagerProvider`, `retryManagerProvider`
- `diagnosticsCollectorProvider`, `transferRecoveryManagerProvider`, `receivedChunkStoreProvider`
- `transferSchedulerProvider`, `throughputMonitorProvider`
- `encryptionKeyProviderProvider`, `sessionKeyExchangeProvider`

Controllers use `ReliableTransferContext()` defaults or `final _keyProvider = EncryptionKeyProvider()` instead.

### Rust / FFI

- `native/photonlink_core/` — version API only; FFI commented out
- `NativeBridgeStub` always used in `bootstrap.dart`
- LZ4 blocked pending FFI

---

## Test Coverage

**Total (post-remediation):** 61 `test()` + 2 `testWidgets()` = **63** cases across 31 files.

### Well covered

- Chunking, reconstruction, integrity, QR codec, reliability primitives
- Compression, encryption, payload pipeline, scheduler, throughput, serialization
- Color Matrix encoder, codec roundtrip, generation, corrupted frames, chunk sizing

### Not covered

| Subsystem | Files |
|-----------|-------|
| QR controllers | `sender_controller.dart`, `receiver_controller.dart` |
| Color Matrix controllers | `color_matrix_sender_controller.dart`, `color_matrix_receiver_controller.dart` |
| Frame diagnostics | `transfer/diagnostics/diagnostics_collector.dart` |
| Persistence | `session_persistence_manager_impl.dart`, `received_chunk_store.dart` |
| Security helpers | `session_key_exchange.dart`, `encryption_key_provider.dart` (partial via pipeline test) |
| Color Matrix encryption metadata | `encoderKeyExchangePayload` / `lastDecodedKeyExchange` path |

### Weak / placeholder tests

- `compression_test.dart` — LZ4 disabled placeholder only
- `phase4_benchmark_test.dart` — prints timings, minimal assertions
- `throughput_test.dart` — `averageBytesPerSec >= 0`
- `color_frame_generation_test.dart` — "cells roundtrip" uses identity copy
- `large_transfer_test.dart` — chunk sizing only, no full encode path

---

## Security Findings

| ID | Severity | Finding |
|----|----------|---------|
| S-01 | **High** | Session key transmitted in plaintext on optical channel (QR setup frame + Color Matrix metadata JSON). No ECDH. |
| S-02 | **High** | Color Matrix receiver writes file and sets `phase: completed` even when SHA-256 verification fails (fails open). |
| S-03 | **High** | Color Matrix skips wire SHA-256 verification before decrypt (QR enforces at `receiver_controller.dart:247`). |
| S-04 | **Med** | Color Matrix output filename not sanitized (QR sanitizes at `receiver_controller.dart:277`). |
| S-05 | **Med** | Resume persistence drops session key and compression/encryption flags. |
| S-06 | **Med** | Color Matrix metadata key re-broadcast every cyclic metadata frame. |
| S-07 | **Low** | Color Matrix receiver does not clear `EncryptionKeyProvider` on complete. |
| S-08 | **Info** | ChaCha20-Poly1305 usage is correct (fresh nonce per encrypt, MAC verified on decrypt). |

See `docs/SECURITY.md` for QR-focused review; Color Matrix gaps documented here.

---

## Documentation Accuracy

| Doc claim | Reality | Severity |
|-----------|---------|----------|
| Color Matrix up to 2 MB | `validateFileSize` caps at 512 KB | **High** |
| `COLOR_MATRIX_FORMAT.md` encryption: `none` \| `chacha20_poly1305` | Code uses `disabled` \| `enabled` enum names | Med |
| Format doc lists `kdfSalt`, `encryptionNonce` | Not implemented in codec | Med |
| `PHASE6_READINESS.md` "matching passphrase" | Random session key, not passphrase | Med |
| `SETUP.md` Phase 1 limitations | Obsolete (transfer works, history persists) | Low |
| `photonlink_app/README.md` | Flutter template, not project README | Low |
| Test count "38" / "50" in old notes | Actual: 58 | Low (current README has no wrong count) |

---

## Prioritized Remediation Backlog

| Priority | ID | Action | Effort |
|----------|-----|--------|--------|
| **P0** | S-02, S-03, S-04 | Align Color Matrix receiver with QR integrity gates; fail closed; sanitize filename | Small |
| **P0** | S-07 | Clear key provider on Color Matrix complete/reset | Trivial |
| **P1** | DOC-01 | Enforce `maxColorMatrixFileBytes` (2 MB) on Color Matrix path | Small |
| **P1** | DOC-02 | Fix `COLOR_MATRIX_FORMAT.md`, `SETUP.md`, `photonlink_app/README.md`, `PHASE6_READINESS.md` | Small |
| **P1** | DOC-03 | Extend `SECURITY.md` for Color Matrix key delivery | Small |
| **P2** | ARCH-01 | Remove dead `protocol_registry` + `protocols/impl` stubs | Small |
| **P2** | ARCH-02 | Remove dead files (`session_store`, `performance_diagnostics`, unused retry_policy) | Small |
| **P2** | ARCH-03 | Remove unused Riverpod providers; rename frame `TransferDiagnostics` → `FrameDiagnostics` | Medium |
| **P3** | TEST-01 | Add Color Matrix encryption-metadata codec test | Small |
| **P3** | TEST-02 | Add Color Matrix receiver finalize / integrity tests | Medium |
| **P3** | TEST-03 | Add persistence + `FrameDiagnosticsCollector` tests | Medium |

---

## Remediation Status

Fixes applied in the audit remediation pass:

| Item | Status |
|------|--------|
| P0 — Color Matrix fail-closed integrity, wire hash, filename sanitize, key clear | **Done** |
| P1 — 2 MB Color Matrix limit enforced, docs updated (`COLOR_MATRIX_FORMAT`, `SETUP`, `SECURITY`, `photonlink_app/README`, `PHASE6_READINESS`) | **Done** |
| P2 — Removed `protocol_registry`, `protocols/impl/*`, `session_store`, `performance_diagnostics`, unused `retry_policy`; renamed `FrameDiagnostics` / `FrameDiagnosticsCollector`; trimmed unused providers | **Done** |
| P3 — Added tests: encryption metadata codec, frame diagnostics collector, transfer limits, session persistence | **Done** |

---

## References

- Phase briefs: agent transcripts `f80e9032` (P1), `3b08fddd` (P2–4), `56b83849` (P5)
- Architecture: `docs/ARCHITECTURE.md`
- Security: `docs/SECURITY.md`
- Color Matrix format: `docs/COLOR_MATRIX_FORMAT.md`
