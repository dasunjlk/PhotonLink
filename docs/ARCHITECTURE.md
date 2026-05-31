# PhotonLink Architecture

## Overview

PhotonLink is an offline peer-to-peer file transfer platform using optical communication (QR codes, color matrices, visual frame streams). Phase 1 establishes the foundation: clean architecture, modern UI, navigation, settings, and protocol abstractions — without real transfer logic.

## Layer Diagram

```
┌─────────────────────────────────────────────────┐
│                   features/                      │
│  home · transfer_setup · camera_scan · pick · about │
├─────────────────────────────────────────────────┤
│  settings/  │  history/  │  shared/widgets/     │
├─────────────────────────────────────────────────┤
│  protocols/  │  services/  │  ui/ (tokens)       │
├─────────────────────────────────────────────────┤
│                    core/                         │
│  bootstrap · router · theme · constants · errors │
└─────────────────────────────────────────────────┘
         │                              │
         ▼                              ▼
   SharedPreferences              native/photonlink_core
   (local storage)               (Rust stub — Phase 2 FFI)
```

## Dependency Rules

| Layer | May import from | Must NOT import |
|-------|----------------|-----------------|
| `ui/` | (none — leaf) | everything else |
| `core/` | `ui/`, `services/` | `features/` |
| `services/` | `core/` | widgets, features |
| `protocols/` | `core/` | widgets, features |
| `shared/` | `ui/` | features |
| `features/` | all above | — |
| `settings/`, `history/` | services, ui, shared | features |

## State Management

**Riverpod 2** with plain providers (no code generation):

- `settingsProvider` — `StateNotifier<AppSettings>` with SharedPreferences persistence
- `historyProvider` — `AsyncNotifier<List<TransferRecord>>` with mock repository
- `protocolRegistryProvider` — maps `TransferMethod` → protocol bundle
- `appRouterProvider` — go_router configuration

## Navigation

**go_router** with declarative routes:

| Route | Screen |
|-------|--------|
| `/` | Home |
| `/transfer/:method` | Transfer Setup (Send/Receive) |
| `/scan?method=` | Camera Scan |
| `/pick?method=` | File Picker |
| `/settings` | Settings |
| `/history` | History |
| `/about` | About |

## Protocol Abstraction

Each transfer method implements five interfaces:

```dart
abstract interface class Encoder<TIn, TOut> { ... }
abstract interface class Decoder<TIn, TOut> { ... }
abstract interface class Packetizer { ... }
abstract interface class ChecksumValidator { ... }
abstract interface class SessionManager { ... }
```

Phase 1 provides placeholder implementations that throw `UnimplementedError`. The `ProtocolRegistry` maps methods to bundles for future DI.

### Adding a New Transfer Method

1. Add enum value to `TransferMethod` in `protocols/transfer_method.dart`
2. Create `protocols/impl/<method>_protocol.dart` implementing all five interfaces
3. Register in `protocolRegistryProvider` in `protocols/protocol_registry.dart`
4. Add home card if the method should appear on the home screen
5. Implement the Rust counterpart in `native/photonlink_core/src/protocols/`

## Native Bridge

Phase 1 uses a Dart stub (`NativeBridgeStub`) implementing `PhotonLinkNative`:

```dart
abstract interface class PhotonLinkNative {
  Future<String> coreVersion();
  Future<String> ping();
}
```

Phase 2 will replace this with `flutter_rust_bridge` bindings to `native/photonlink_core`.

## UI Design System

| Token file | Purpose |
|------------|---------|
| `ui/colors.dart` | Brand palette, gradients, glass tints |
| `ui/typography.dart` | Inter font scale |
| `ui/spacing.dart` | 4px-based spacing scale |
| `ui/motion.dart` | Animation durations and curves |
| `ui/radii.dart` | Border radius tokens |

Key widgets: `GlassCard` (backdrop blur), `GradientScaffold` (animated background), `ScanFrameOverlay` (camera framing).

## Rust Core (Phase 1 Skeleton)

Located at `native/photonlink_core/`. Mirrors Dart protocol traits:

- `Encoder`, `Decoder`, `Packetizer`, `ChecksumValidator`, `SessionManager`
- `core_version()` public API
- Commented FFI skeleton in `src/ffi.rs`

Not built or linked by the Flutter build in Phase 1.

## Phase 2 Roadmap

- [ ] Wire Rust core via flutter_rust_bridge
- [ ] Implement QR encoding/decoding
- [ ] Implement Color Matrix protocol
- [ ] Implement Optical Stream protocol
- [ ] Real file transmission pipeline
- [ ] Persistent transfer history
- [ ] Compression and encryption
- [ ] Audio and Flash transfer methods
- [ ] iOS and desktop platform support
