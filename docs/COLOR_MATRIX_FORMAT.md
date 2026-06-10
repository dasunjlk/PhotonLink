# Color Matrix Frame Format (PLCM v1)

## Overview

Color Matrix Transport encodes transfer packets as RGB cells in a configurable grid (16×16, 24×24, or 32×32). Frames are displayed as animated rasters and captured by the receiver camera.

Default grid size in app settings is **24×24**.

## Binary Frame Structure

```
PLCM | version(1) | type(M=0,D=1) | sessionIdLen | sessionId |
     frameId(u32) | packetId(u32) | totalPackets(u32) | gridSize(u32) |
     bitsPerChannel(1) | payloadLen(u32) | payload | crc32(u32)
```

| Field | Description |
|-------|-------------|
| protocolVersion | Always `1` for Phase 5 |
| sessionId | Transfer session identifier |
| frameId | Monotonic stream frame counter |
| packetId | Chunk index (0 for metadata) |
| payload | Metadata JSON or raw chunk bytes |
| checksum | CRC32 over all preceding bytes |
| gridSize | Data grid dimension (excludes margin) |
| bitsPerChannel | Default `2` (64-color palette) |

## Color Encoding

- Each cell carries 6 bits (2 bits per RGB channel)
- Palette levels: 0, 85, 170, 255 per channel
- Deterministic mapping via `ColorEncoder` / `ColorDecoder`

## Visual Frame Layout

```
┌─────────────────────────────────┐
│ ■ sync border (checkerboard)    │
│ ┌─ RED ─────── GREEN ─┐         │
│ │   data grid         │         │
│ │                     │         │
│ └─ BLUE ────── YELLOW ┘         │
└─────────────────────────────────┘
```

- **Orientation markers**: Red=TL, Green=TR, Blue=BL, Yellow=BR
- **Sync border**: Alternating black/white for frame alignment

## Metadata JSON (wire payload in metadata frame)

Base fields (aligned with PL2 `MetadataPacket`):

| Field | Type | Notes |
|-------|------|-------|
| `fileName` | string | Original file name |
| `fileSize` | int | Wire payload size (post compress/encrypt) |
| `totalChunks` | int | Data packet count |
| `sha256` | string | SHA-256 of wire payload |
| `mimeType` | string | MIME type |
| `protocolVersion` | int | `2` for Phase 4 transforms |
| `compression` | string | `none` \| `gzip` \| `lz4` (enum name) |
| `encryption` | string | `disabled` \| `enabled` (enum name) |
| `originalSize` | int? | Plaintext size before transforms |
| `originalSha256` | string? | SHA-256 of original plaintext |

Color Matrix–specific (when encryption enabled):

| Field | Type | Notes |
|-------|------|-------|
| `keyExchangePayload` | string? | Base64-encoded 256-bit session key (no separate setup QR) |

**Security note:** The session key is visible on the optical channel. Encryption protects ciphertext from parties who do not capture the key frame. See `docs/SECURITY.md`.
