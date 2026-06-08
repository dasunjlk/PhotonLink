# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth.

## Status: Phase 5 — Color Matrix Transport

This release adds **Color Matrix optical transfer** alongside the existing QR MVP:

- **QR Transfer** — scannable QR frame streaming (unchanged)
- **Color Matrix Transfer** — RGB grid encoding with camera capture
- Transport-agnostic protocol stack: compression (gzip), encryption (ChaCha20-Poly1305), reliability, diagnostics
- Configurable matrix size (16/24/32), frame rate, quality settings
- Persistent transfer history per transport method
- 38 automated tests

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

**QR transfer:** Device A → QR Transfer → Send → pick file. Device B → QR Transfer → Receive → scan.

**Color Matrix:** Device A → Color Matrix → Send → pick file. Device B → Color Matrix → Receive → align matrix in camera frame.

See [docs/SETUP.md](docs/SETUP.md) for platform setup.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.22+, Dart 3.3+ |
| State | Riverpod 2 |
| Navigation | go_router |
| QR | qr_flutter, mobile_scanner |
| Color Matrix | camera, image, CustomPainter |
| Encryption | cryptography (ChaCha20-Poly1305) |
| Integrity | crypto (SHA-256) |

## Project Structure

```
photonlink_app/lib/
├── protocols/         # Interfaces + transport registry
├── transfer/
│   ├── core/          # Chunking, reconstruction, pipeline
│   ├── compression/   # gzip strategies
│   ├── encryption/    # ChaCha20 strategies
│   ├── reliability/   # Missing packets, retry, recovery
│   ├── diagnostics/   # Transfer metrics
│   ├── qr/            # QR codec + transport
│   ├── color_matrix/  # Color encoder/decoder/generator/detector
│   └── application/   # Family controllers
├── features/
│   ├── qr_transfer/
│   └── color_matrix_transfer/
└── settings/
```

## Tests

```bash
cd photonlink_app
flutter test
```

## Documentation

- [Setup Guide](docs/SETUP.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Color Matrix Format](docs/COLOR_MATRIX_FORMAT.md)
- [Performance Summary](docs/PHASE5_PERFORMANCE.md)
- [Phase 6 Readiness](docs/PHASE6_READINESS.md)

## License

See [LICENSE](LICENSE).
