# Optical Stream Format (PLOS v1)

## Overview

PhotonLink Optical Stream uses wire format **PLOS** (PhotonLink Optical Stream) for continuous chunk-based packets encoded as high-density binary brightness grids.

## Wire Layout

| Field | Size | Description |
|-------|------|-------------|
| Magic | 4 bytes | `PLOS` |
| Protocol Version | 1 byte | `1` |
| Packet Type | 1 byte | `0=metadata, 1=data, 2=parity` |
| Session ID Length | 1 byte | UTF-8 length |
| Session ID | variable | UTF-8 string |
| Stream ID | 2 bytes | u16 BE |
| Frame ID | 4 bytes | u32 BE (encoder sequence) |
| Packet ID | 4 bytes | u32 BE (chunk/parity id) |
| Total Packets | 4 bytes | u32 BE |
| Sync Marker | 2 bytes | u16 BE (`0xA55A` default) |
| Timestamp | 8 bytes | u64 BE (ms since epoch) |
| Grid Size | 4 bytes | u32 BE |
| Bits Per Cell | 1 byte | density (default 3) |
| Payload Length | 4 bytes | u32 BE |
| Payload | variable | raw bytes |
| Checksum | 4 bytes | CRC32 of preceding bytes |

## Visual Encoding

- **Sync lanes:** alternating border pattern for grid lock
- **Timing lanes:** calibration row/column for clock drift tolerance
- **Payload lanes:** multi-bit brightness cells (default 3 bits/cell)
- **Finder markers:** corner orientation patterns

## Implementations

- Dart: `lib/transfer/optical_stream/optical_stream_serializer.dart`
- Rust: `photonlink_core/src/packet/plos.rs`
