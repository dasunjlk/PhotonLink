# Rust Security Review (Phase 8)

## Scope

Security review of the `photonlink_core` Rust crate and FFI boundary for Phase 8 migration.

## Memory Safety

### Rust Guarantees
- All core logic written in safe Rust (no `unsafe` blocks in application code)
- Buffer bounds checked on all slice operations
- `Vec<u8>` used for dynamic buffers — no manual allocation

### FFI Boundary
- Data crosses boundary as owned `Vec<u8>` via FRB — no dangling pointers
- `ReconstructionHandle` is opaque — internal state not exposed to Dart
- `catch_unwind` wraps all FFI entrypoints — panics cannot crash the Flutter isolate

## Key Handling

### Encryption Module
- Session keys received as `&[u8]`, validated for 32-byte length
- Intermediate `ct_with_tag` buffer zeroized via `zeroize` crate after decrypt
- Keys are NOT stored in Rust — passed per-call from Dart `EncryptionKeyProvider`

### Recommendations
- [ ] Enable `zeroize` on session key `Vec<u8>` at FFI ingress (future hardening)
- [ ] Consider `SecretVec<u8>` wrapper for key material in FRB DTOs

## Buffer Handling

| Operation | Validation |
|-----------|-----------|
| PLCM deserialize | Minimum 24 bytes, CRC32 validation, bounds checks on all fields |
| PL2 decode | Exactly 6 pipe-separated fields, session ID length 1–128 |
| Encryption decrypt | Minimum 28 bytes (12 nonce + 16 mac) |
| Chunk split | Rejects chunk_size == 0 |
| FEC decode | k + m ≤ 255, erasures ≤ parity count |

### Overflow Protection
- All length calculations use `usize` with explicit bounds checks
- PLCM `payloadLen` validated against remaining buffer size before allocation

## Error Propagation

```
Rust CoreError → catch_core() → Result<T, String> → Dart exception
```

Error categories:
- `InvalidInput` — caller error, safe to retry with corrected input
- `ChecksumMismatch` — data corruption detected, discard frame
- `DecodeFailed` — malformed packet, discard frame
- `CompressionFailed` / `EncryptionFailed` — transform failure
- `RecoveryFailed` — FEC cannot recover, fall back to retransmission
- `InternalPanic` — unexpected, log and fall back to Dart backend

No error exposes internal Rust state or stack traces across FFI.

## Panic Recovery

All public FFI functions wrapped in `catch_core()`:

```rust
pub fn catch_core<F, T>(f: F) -> CoreResult<T>
where F: FnOnce() -> CoreResult<T>
{
    match catch_unwind(AssertUnwindSafe(f)) {
        Ok(result) => result,
        Err(payload) => Err(CoreError::InternalPanic(...)),
    }
}
```

If Rust panics, Dart receives a structured error — the app continues with Dart backend fallback.

## Threat Model Notes

| Threat | Mitigation |
|--------|-----------|
| Malformed optical frames | Strict parse validation + CRC32 |
| Buffer overflow via large payloads | Length checks before allocation |
| Key extraction from Rust memory | Keys not persisted; zeroize on drop |
| Panic-based DoS | catch_unwind at FFI boundary |
| Protocol downgrade | No protocol changes in Phase 8 |

## Dart Backend Fallback

If Rust backend fails or is unavailable, `CoreBackend.dart` provides identical behavior using battle-tested Dart implementations from Phases 1–7.

## Verdict

Rust core follows memory-safe patterns with structured error propagation and panic recovery. Key handling relies on Dart-side `EncryptionKeyProvider` — no keys stored in Rust. Ready for production activation after toolchain validation and FRB integration testing.
