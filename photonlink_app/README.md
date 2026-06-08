# PhotonLink App

Flutter client for **PhotonLink** — offline peer-to-peer optical file transfer.

## Quick Start

```bash
flutter pub get
flutter run
flutter test
flutter analyze
```

## Transports

| Method | Route prefix | Max file size |
|--------|--------------|---------------|
| QR (bidirectional ACK/NAK) | `/qr/*` | 512 KB |
| Color Matrix (cyclic broadcast) | `/color-matrix/*` | 2 MB |

## Project layout

```
lib/
├── core/           # Bootstrap, router, theme, constants
├── features/       # Screens (home, qr_transfer, color_matrix_transfer, …)
├── transfer/       # Transfer engine (QR, color_matrix, reliability, encryption)
├── protocols/      # Interfaces + transport_registry
├── settings/       # App settings
├── history/        # Transfer history
└── shared/         # Reusable widgets
```

## Documentation

See the repository root:

- [README](../README.md)
- [Architecture](../docs/ARCHITECTURE.md)
- [Phase 1–5 Audit](../docs/AUDIT_PHASE1-5.md)
- [Color Matrix Format](../docs/COLOR_MATRIX_FORMAT.md)
- [Security](../docs/SECURITY.md)
- [Setup](../docs/SETUP.md)
