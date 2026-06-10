# Phase 5 Performance Summary

## Measured Areas

| Metric | QR Transport | Color Matrix (16×16) |
|--------|-------------|------------------------|
| Frame generation | ~1ms (string encode) | ~15–30ms (raster PNG) |
| Frame decode | ~0.5ms (string parse) | ~5–15ms (cell sampling) |
| Camera processing | N/A (barcode SDK) | ~50–200ms/frame (YUV→RGB) |
| Memory per frame | ~2 KB | ~50–100 KB (raster) |

## Bottlenecks

1. **Color raster generation** — PNG encoding dominates sender CPU
2. **Camera YUV conversion** — Full-frame RGB conversion on each stream frame
3. **Cell sampling** — Perspective interpolation per grid cell
4. **No GPU acceleration** — All processing is CPU-bound (Phase 6+)

## Throughput (MVP estimates)

- Color Matrix @ 4 fps, 16×16 grid: ~3–8 KB/s effective (depends on chunk size)
- QR @ 2 fps: ~1–2 KB/s (limited by frame char capacity)

## Recommendations for Phase 6

- Raw RGB display without PNG round-trip on sender
- Downsampled camera processing region (ROI crop)
- Isolate color classification to native/Rust FFI
- Adaptive grid sizing based on link quality
