# Adaptive Optical Engine (Phase 6)

## Overview

PhotonLink Phase 6 adds a **transport-agnostic Adaptive Optical Engine** that monitors real-world transfer conditions and adjusts optical parameters for stability and throughput.

Module path: `photonlink_app/lib/transfer/adaptive/`

## Architecture

```
CapabilityProfile ──┐
EnvironmentProfile ├──► QualityScoreCalculator ──► AdaptationEngine
FrameDiagnostics ───┘         │                        │
                                │                        ▼
                    LightingCompensationManager    AdaptiveParameters (tiers)
                                                         │
                                                         ▼
                                              ColorMatrixParameterMapper
                                                         │
                                    ┌────────────────────┴────────────────────┐
                                    ▼                                         ▼
                            Sender (live FPS)                    Receiver (cadence, overlays)
```

## Components

| Component | Role |
|-----------|------|
| `DeviceCapabilityDetector` | CPU cores, memory, display refresh/size, camera estimate |
| `EnvironmentAnalyzer` | Rolling brightness, detection/decode/loss rates |
| `QualityScoreCalculator` | 0–100 score from diagnostics + environment |
| `PayloadDensityManager` | Maps density tier ↔ bits-per-channel |
| `AdaptationEngine` | Cooldown, hysteresis, single-step tier changes |
| `LightingCompensationManager` | Brightness/contrast recommendations (no hardware control) |
| `AdaptationDiagnostics` | Decision log, quality/environment history |
| `ColorMatrixParameterMapper` | Tiers → gridSize (16/24/32/48), bpc, fps |
| `FecAdaptationPolicy` | Recommends FEC redundancy adjustments (Phase 7) |

## FEC Integration (Phase 7)

When **Adaptive FEC** is enabled in Settings, `AdaptiveSessionController.evaluateFecAdaptation()` adjusts `FecConfiguration` based on quality score and environment:

- High loss/decode error → increase redundancy tier
- Clean channel → decrease redundancy tier
- `FecStatistics` feeds into `QualityScoreCalculator` recovery factor (15% weight when FEC active)

See [FEC_ARCHITECTURE.md](FEC_ARCHITECTURE.md).

## Transport Profiles

| Profile | Behavior |
|---------|----------|
| **Safe** | Lower FPS, smaller matrix tendency, low density |
| **Balanced** | Default trade-off |
| **Performance** | Higher FPS, larger matrix tendency |

Manual override: Settings → Profile Override (auto/safe/balanced/performance).

## Quality Score (0–100)

| Factor | Weight |
|--------|--------|
| Frame loss | 25% |
| Decode errors | 30% |
| Retries | 10% |
| Detection stability | 25% |
| Brightness conditions | 10% |

When FEC is active, weights renormalize to include **Recovery factor** at 15% (frame loss 20%, decode 25%, retry 8%, detection 22%, brightness 10%).

## Adaptation Flow

1. **Session start**: Capability + last quality score → initial matrix size, density, FPS.
2. **During transfer (sender)**: Live FPS adjustment only (closed-loop on sender metrics).
3. **During transfer (receiver)**: Environment + decode feedback → quality score, processing throttle, lighting hints.
4. **Cooldown**: 3–8 s between changes (gentle/normal/aggressive).
5. **Hysteresis**: 3–8 consecutive poor/good samples before a change.

## Known Limitations

- Color Matrix is **one-way** — sender cannot see receiver decode quality in real time.
- Grid size and density are fixed **per session** (embedded in frame header).
- Cross-device grid negotiation requires a future handshake (Phase 7+).
- No Reed-Solomon, fountain codes, GPU acceleration, ML, or audio/stream transport.

## Settings

- Adaptive Mode toggle
- Aggressiveness (gentle / normal / aggressive)
- Profile override
- Quality monitoring overlay
- Manual matrix size (16–48) and density (1–3 bpc)
- Diagnostics JSON export

## Tests

```powershell
cd photonlink_app
flutter test test/transfer/adaptive/
```

See `docs/PHASE6_PERFORMANCE.md` for overhead measurements.
