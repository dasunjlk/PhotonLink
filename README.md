# PhotonLink

**Offline peer-to-peer file transfer using optical communication.**

PhotonLink enables file transfer between devices using only screens and cameras — no network, no servers, no Bluetooth. Transfer methods include QR code streams, color matrices, and visual frame encoding.

## Status: Phase 1 — Foundation

This release establishes the app scaffold:

- Modern animated UI with dark/light themes and glassmorphism cards
- Navigation with go_router (home, settings, history, camera, file picker, about)
- Settings system with persistent preferences
- Transfer history UI with mock data
- Camera preview prototype with scan framing overlay
- Local file picker prototype
- Protocol abstraction layer (interfaces only, no implementations)
- Rust core skeleton (not yet wired via FFI)

**No real file transfer or optical encoding in this phase.**

## Quick Start

```bash
cd photonlink_app
flutter pub get
flutter run
```

See [docs/SETUP.md](docs/SETUP.md) for full setup instructions including platform initialization.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.22+, Dart 3.3+ |
| State | Riverpod 2 |
| Navigation | go_router |
| Core Engine | Rust (skeleton, Phase 2 FFI) |
| Platform | Android first, iOS/desktop planned |

## Project Structure

```
PhotonLink/
├── photonlink_app/          # Flutter app
│   └── lib/
│       ├── core/            # Bootstrap, router, theme
│       ├── features/        # Screens
│       ├── shared/          # Reusable widgets
│       ├── services/        # Storage, permissions, logger
│       ├── protocols/       # Transfer interfaces
│       ├── settings/        # Settings module
│       ├── history/         # History module
│       └── ui/              # Design tokens
├── native/photonlink_core/  # Rust engine skeleton
└── docs/                    # Architecture & setup guides
```

## Dependencies

- `flutter_riverpod` — state management
- `go_router` — navigation
- `camera` — camera preview
- `file_picker` — local file selection
- `permission_handler` — runtime permissions
- `shared_preferences` — settings persistence
- `google_fonts` — Inter typography
- `flutter_animate` — entry animations
- `package_info_plus` — app version
- `logger` — structured logging
- `intl` — date formatting

## Documentation

- [Setup Guide](docs/SETUP.md)
- [Architecture](docs/ARCHITECTURE.md)

## License

MIT — see [LICENSE](LICENSE).
