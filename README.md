# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth.

## Status: Phase 4 — Efficiency & Security

Builds on Phase 3 reliable bidirectional QR transfer with:

- **Compression** — GZip (active); LZ4 placeholder for future Rust core
- **Encryption** — optional ChaCha20-Poly1305; session key via setup QR
- **Payload pipeline** — compress → encrypt → chunk (send); reverse on receive
- **Transfer scheduler** — normal (2 fps) vs performance (4 fps)
- **Throughput monitor** — speed, compression ratio, encryption overhead
- **Expanded diagnostics** — ACK/NAK counts, compression savings, exportable reports
- **Settings** — compression, encryption, transfer mode, diagnostics toggle
- **History v3** — compression/encryption used, ratio, speed, protocol version

Supported file types: `txt`, `pdf`, `jpg`, `png`, `zip` (max **512 KB**).

**Not in this phase:** Color Matrix, Optical Stream, Audio, Reed-Solomon, fountain codes, real LZ4 FFI, ECDH key exchange.

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

Enable **Compression** and/or **Encryption** in Settings before transferring.

**Two-device flow:** Sender shows setup QR (if encryption on) → metadata → data rounds. Receiver scans setup first when encrypted, then metadata and data. NAK/ACK recovery unchanged from Phase 3.

## Tests

```bash
cd photonlink_app
flutter test
flutter analyze
```

**50 tests** including compression, encryption, pipeline integrity, range serialization, scheduler, throughput, setup codec, benchmarks, and Phase 1–3 suites.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Security review](docs/SECURITY.md)
- [Phase 4 benchmarks](docs/PHASE4_BENCHMARKS.md)
- [Setup](docs/SETUP.md)

## Phase 5 readiness

Transport-agnostic compression, encryption, scheduler, and metrics are ready for Color Matrix / Optical Stream / Audio. Next: new encoders/decoders per transport, ECDH pairing, Rust LZ4 core, SQLite history.

## License

See [LICENSE](LICENSE).
