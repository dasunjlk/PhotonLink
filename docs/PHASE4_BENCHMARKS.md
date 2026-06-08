# Phase 4 Performance Benchmarks

Captured from `test/transfer/benchmarks/phase4_benchmark_test.dart` on a representative dev machine (results vary by hardware).

| Benchmark | Result |
|-----------|--------|
| GZip 32 KB | ~4 ms, ratio ~0.02 (highly compressible test pattern) |
| ChaCha20-Poly1305 32 KB wire | ~13 ms |
| ACK ID list (500 ids) | Range 5 B vs JSON 1891 B (~100% smaller) |
| QR encode 100 frames | ~4.5 ms total |

## Serialization finding

ACK/NAK/Handshake IDs use **range encoding** (`0-3,7,9-12`) instead of JSON arrays, dramatically reducing frame size for large chunk counts.

## Bottlenecks (typical)

1. QR display/scan rate (human + camera), not CPU
2. Encryption on full payload at session end (whole-file AEAD)
3. Per-frame base64 overhead on data chunks

## Future work

- Rust core for LZ4 and chunking
- Per-chunk or streaming encryption for very large files
- Binary PL3 wire format (optional)
