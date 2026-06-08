# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth.

## Status: Phase 5 — Color Matrix + Phase 4 Stack

This release merges **Phase 4** (efficiency & security) with **Phase 5** (Color Matrix transport):

- **QR Transfer** — reliable bidirectional transfer with ACK/NAK recovery
- **Color Matrix Transfer** — RGB grid encoding with live camera decode
- **Compression** — GZip (active); LZ4 placeholder
- **Encryption** — optional ChaCha20-Poly1305 (setup QR for QR; key embedded in metadata for Color Matrix)
- **Payload pipeline** — compress → encrypt → chunk (send); reverse on receive
- **Transport registry** — pluggable encoders/decoders per method
- **Settings** — compression, encryption, transfer mode, Color Matrix grid size & frame rate
- **History** — per-method records with compression/encryption metadata

Supported file types: `txt`, `pdf`, `jpg`, `png`, `zip` (QR max **512 KB**; Color Matrix up to **2 MB**).

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

**QR transfer:** Device A → QR Transfer → Send → pick file. Device B → QR Transfer → Receive → scan setup (if encrypted), metadata, and data frames.

**Color Matrix:** Device A → Color Matrix → Send → pick file. Device B → Color Matrix → Receive → align matrix in camera frame.

Enable **Compression** and/or **Encryption** in Settings before transferring.

See [docs/SETUP.md](docs/SETUP.md) for platform setup.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.22+, Dart 3.3+ |
| State | Riverpod 2 |
| Navigation | go_router |
| QR | qr_flutter, mobile_scanner |
| Color Matrix | camera, image |
| Encryption | cryptography (ChaCha20-Poly1305) |
| Integrity | crypto (SHA-256) |

## Tests

```bash
cd photonlink_app
flutter test
flutter analyze
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Color Matrix Format](docs/COLOR_MATRIX_FORMAT.md)
- [Security review](docs/SECURITY.md)
- [Phase 4 benchmarks](docs/PHASE4_BENCHMARKS.md)
- [Performance Summary](docs/PHASE5_PERFORMANCE.md)
- [Phase 6 Readiness](docs/PHASE6_READINESS.md)
- [Setup](docs/SETUP.md)

## License

See [LICENSE](LICENSE).
