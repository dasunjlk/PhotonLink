# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth.

## Status: Phase 3 — Reliable QR Transfer

This release adds **reliable, round-based, bidirectional QR transfer** with a transport-agnostic reliability layer:

- **ACK / NAK** batch confirmation and missing-packet recovery
- **Handshake** with `receivedChunkIds` for resume after interruption
- **Control packets** (`ready`, `endOfRound`, `complete`, `pause`, `cancel`, `resumeRequest`)
- **13-phase state machine** with validated transitions
- **Retry policy** (max retries, per-packet counts, permanent failure detection)
- **Diagnostics** (sent/received/missing/retries/duplicates, throughput, ETA)
- **Per-chunk disk persistence** + session index for resume
- **Two-device UI:** each screen hosts QR display *and* camera, switched by phase
- **History v2:** `sessionId`, `durationMs`, `retryCount`, `failureReason`, detail view

Supported file types: `txt`, `pdf`, `jpg`, `png`, `zip` (max **512 KB**).

**Not in this phase:** Color Matrix, Optical Stream, Audio, Rust FFI, compression, encryption, Reed-Solomon, fountain codes.

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

**Manual two-device QR test:**

1. **Device A (sender):** QR Transfer → Send → pick file → Start. Show metadata QR; when prompted, scan Device B’s handshake/status QRs.
2. **Device B (receiver):** QR Transfer → Receive → scan A’s metadata, then data QRs. When complete, show NAK/ACK or completion QR for A to scan.
3. Repeat data/status rounds until progress reaches 100% and SHA-256 verifies.
4. Use **Show status / Resume sending** if turn handoff is missed.

See [docs/SETUP.md](docs/SETUP.md) for platform setup.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.22+, Dart 3.3+ |
| State | Riverpod 2 |
| Navigation | go_router |
| QR render | qr_flutter (ECC level H) |
| QR scan | mobile_scanner |
| Integrity | crypto (SHA-256) |
| Storage | shared_preferences, path_provider |

## Project Structure

```
PhotonLink/
├── photonlink_app/lib/
│   ├── core/              # Bootstrap, router, theme
│   ├── protocols/
│   │   ├── interfaces/    # Packets + reliability interfaces
│   │   └── impl/          # QrProtocol
│   ├── transfer/
│   │   ├── core/          # Chunking, reconstruction, integrity
│   │   ├── reliability/   # ACK/NAK/retry/diagnostics (no Flutter)
│   │   ├── state/         # 13-phase state machine
│   │   ├── persistence/   # Chunk store + session index
│   │   ├── qr/            # PL2 codec + stream controller
│   │   └── application/   # Sender/receiver controllers + providers
│   ├── features/qr_transfer/
│   ├── history/
│   └── ...
├── native/photonlink_core/
└── docs/
```

## Tests

```bash
cd photonlink_app
flutter test
flutter analyze
```

**35+ tests** including reliability (ACK/NAK/retry), state machine transitions, QR reliability codec roundtrips, resume/recovery integration, and widget smoke tests.

## Documentation

- [Setup Guide](docs/SETUP.md)
- [Architecture](docs/ARCHITECTURE.md) — reliability layer, bidirectional sequence, state diagram, limitations, Phase 4 notes

## License

See [LICENSE](LICENSE).
