# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth.

## Status: Phase 2 — QR Transfer MVP

This release adds **QR-based optical file transfer** for small files:

- Supported types: `txt`, `pdf`, `jpg`, `png`, `zip`
- Session metadata (ID, file name, size, chunk count, SHA-256)
- Fixed-size chunking with reconstruction and duplicate handling
- High-ECC QR frame streaming (adjustable frame rate on sender)
- Continuous QR scanning on receiver (`mobile_scanner`)
- SHA-256 integrity verification
- Persistent transfer history
- Session progress persistence (resume-ready foundation)

**Not in this phase:** Color Matrix, Optical Stream, Audio, Rust FFI, encryption, compression, advanced ECC.

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

**Manual QR transfer test:** Device A → QR Transfer → Send → pick file → Start Transmission. Device B → QR Transfer → Receive → scan sender screen until progress completes.

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
│   ├── protocols/         # Interfaces + QrProtocol
│   ├── transfer/
│   │   ├── core/          # Chunking, reconstruction, integrity (reusable)
│   │   ├── qr/            # QR codec + stream (isolated)
│   │   └── application/   # Riverpod controllers
│   ├── features/
│   │   └── qr_transfer/   # Sender, receiver, completion UI
│   ├── history/           # Persistent history
│   ├── settings/
│   ├── services/
│   └── ui/
├── native/photonlink_core/
└── docs/
```

## Dependencies (Phase 2)

**Core:** `flutter_riverpod`, `go_router`, `shared_preferences`, `file_picker`, `permission_handler`, `google_fonts`, `flutter_animate`, `logger`, `intl`, `package_info_plus`, `camera`

**Phase 2:** `qr_flutter`, `mobile_scanner`, `crypto`, `path_provider`

## Tests

```bash
cd photonlink_app
flutter test
```

15+ unit tests covering chunking, ordering, reconstruction, integrity, QR codec, plus widget smoke tests.

## Documentation

- [Setup Guide](docs/SETUP.md)
- [Architecture](docs/ARCHITECTURE.md)

## License

See [LICENSE](LICENSE).
