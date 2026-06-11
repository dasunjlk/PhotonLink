//! Flutter Rust Bridge API surface — mirrors the six Dart service interfaces.

use flutter_rust_bridge::frb;

use crate::chunking::{self, DataChunk};
use crate::compression::{self, CompressionKind, CompressionOutput};
use crate::diagnostics::{self, QualityScoreInput, QualityScoreOutput};
use crate::encryption;
use crate::error::{catch_core, CoreError, CoreResult};
use crate::fec::{self, FecConfig};
use crate::hashing;
use crate::packet::{self, Pl2Frame, PlcmFrame};
use crate::protocol;
use crate::reconstruction::{self, ReconstructionState};

// ── CoreService ──────────────────────────────────────────────────────────────

#[frb(sync)]
pub fn core_version() -> String {
    crate::core_version().to_string()
}

#[frb(sync)]
pub fn sha256_hex(data: Vec<u8>) -> String {
    hashing::sha256_hex(&data)
}

#[frb(sync)]
pub fn sha256_verify(data: Vec<u8>, expected: String) -> bool {
    hashing::sha256_verify(&data, &expected)
}

#[frb(sync)]
pub fn crc32_compute(data: Vec<u8>) -> u32 {
    protocol::crc32(&data)
}

#[frb(sync)]
pub fn crc32_validate(data: Vec<u8>, expected: u32) -> bool {
    protocol::validate_crc32(&data, expected)
}

// ── PacketService ────────────────────────────────────────────────────────────

#[frb(sync)]
pub fn encode_pl2_data_frame(
    session_id: String,
    chunk_id: u32,
    total_chunks: u32,
    payload: Vec<u8>,
) -> Result<String, String> {
    catch_core(|| {
        packet::encode_pl2_data_frame(&session_id, chunk_id, total_chunks, &payload)
            .map_err(|e| CoreError::EncodeFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn decode_pl2_frame(raw: String) -> Result<Pl2FrameDto, String> {
    catch_core(|| {
        packet::decode_pl2_frame(&raw)
            .map(Pl2FrameDto::from)
            .map_err(|e| CoreError::DecodeFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn encode_plcm_frame(frame: PlcmFrameDto) -> Result<Vec<u8>, String> {
    catch_core(|| {
        packet::encode_plcm_frame(&frame.into())
            .map_err(|e| CoreError::EncodeFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn decode_plcm_frame(bytes: Vec<u8>) -> Result<PlcmFrameDto, String> {
    catch_core(|| {
        packet::decode_plcm_frame(&bytes)
            .map(PlcmFrameDto::from)
            .map_err(|e| CoreError::DecodeFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

// ── Chunking / Reconstruction ────────────────────────────────────────────────

#[frb(sync)]
pub fn chunk_split(
    data: Vec<u8>,
    session_id: String,
    chunk_size: u32,
) -> Result<Vec<DataChunkDto>, String> {
    catch_core(|| {
        chunking::split(&data, &session_id, chunk_size as usize)
            .map(|chunks| chunks.into_iter().map(DataChunkDto::from).collect())
            .map_err(|e| CoreError::InvalidInput(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn chunk_merge(mut chunks: Vec<DataChunkDto>) -> Result<Vec<u8>, String> {
    catch_core(|| {
        let mut rust_chunks: Vec<DataChunk> = chunks.drain(..).map(Into::into).collect();
        chunking::merge(&mut rust_chunks).map_err(|e| CoreError::InvalidInput(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn reconstruction_new() -> ReconstructionHandle {
    ReconstructionHandle {
        inner: ReconstructionState::new(),
    }
}

// ── CompressionService ───────────────────────────────────────────────────────

#[frb(sync)]
pub fn compress_data(input: Vec<u8>, kind: String) -> Result<CompressionOutputDto, String> {
    catch_core(|| {
        compression::compress(&input, parse_compression_kind(&kind)?)
            .map(CompressionOutputDto::from)
            .map_err(|e| CoreError::CompressionFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn decompress_data(
    input: Vec<u8>,
    kind: String,
    original_size: u32,
) -> Result<CompressionOutputDto, String> {
    catch_core(|| {
        compression::decompress(&input, parse_compression_kind(&kind)?, original_size as usize)
            .map(CompressionOutputDto::from)
            .map_err(|e| CoreError::CompressionFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

// ── EncryptionService ────────────────────────────────────────────────────────

#[frb(sync)]
pub fn encrypt_data(plaintext: Vec<u8>, session_key: Vec<u8>) -> Result<Vec<u8>, String> {
    catch_core(|| {
        encryption::encrypt(&plaintext, &session_key)
            .map_err(|e| CoreError::EncryptionFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn decrypt_data(wire: Vec<u8>, session_key: Vec<u8>) -> Result<Vec<u8>, String> {
    catch_core(|| {
        encryption::decrypt(&wire, &session_key)
            .map_err(|e| CoreError::EncryptionFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

// ── DiagnosticsService ───────────────────────────────────────────────────────

#[frb(sync)]
pub fn calculate_quality_score(input: QualityScoreInput) -> QualityScoreOutput {
    diagnostics::calculate_quality_score(&input)
}

// ── FecService ─────────────────────────────────────────────────────────────────

#[frb(sync)]
pub fn fec_encode_block(
    data_symbols: Vec<Vec<u8>>,
    parity_count: u32,
    symbol_length: u32,
) -> Result<Vec<Vec<u8>>, String> {
    catch_core(|| {
        fec::encode_block(&data_symbols, parity_count as usize, symbol_length as usize)
            .map_err(|e| CoreError::RecoveryFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn fec_decode_block(
    data_count: u32,
    parity_count: u32,
    symbol_length: u32,
    erasures: Vec<u32>,
    available_keys: Vec<u32>,
    available_values: Vec<Vec<u8>>,
) -> Result<Option<Vec<Vec<u8>>>, String> {
    catch_core(|| {
        let mut available = std::collections::HashMap::new();
        for (k, v) in available_keys.into_iter().zip(available_values) {
            available.insert(k as usize, v);
        }
        let erasures_usize: Vec<usize> = erasures.iter().map(|&e| e as usize).collect();
        fec::decode_block(
            data_count as usize,
            parity_count as usize,
            symbol_length as usize,
            &erasures_usize,
            &available,
        )
        .map_err(|e| CoreError::RecoveryFailed(e.to_string()))
    })
    .map_err(|e| e.to_string())
}

// ── DTOs ─────────────────────────────────────────────────────────────────────

#[frb]
pub struct Pl2FrameDto {
    pub packet_type: String,
    pub session_id: String,
    pub seq: u32,
    pub total: u32,
    pub payload: Vec<u8>,
}

impl From<Pl2Frame> for Pl2FrameDto {
    fn from(f: Pl2Frame) -> Self {
        Self {
            packet_type: f.packet_type.to_string(),
            session_id: f.session_id,
            seq: f.seq,
            total: f.total,
            payload: f.payload,
        }
    }
}

#[frb]
pub struct PlcmFrameDto {
    pub protocol_version: u8,
    pub session_id: String,
    pub frame_id: u32,
    pub packet_id: u32,
    pub packet_type: u8,
    pub total_packets: u32,
    pub grid_size: u32,
    pub bits_per_channel: u8,
    pub payload: Vec<u8>,
    pub checksum: u32,
}

impl From<PlcmFrame> for PlcmFrameDto {
    fn from(f: packet::PlcmFrame) -> Self {
        Self {
            protocol_version: f.protocol_version,
            session_id: f.session_id,
            frame_id: f.frame_id,
            packet_id: f.packet_id,
            packet_type: f.packet_type.value(),
            total_packets: f.total_packets,
            grid_size: f.grid_size,
            bits_per_channel: f.bits_per_channel,
            payload: f.payload,
            checksum: f.checksum,
        }
    }
}

impl From<PlcmFrameDto> for packet::PlcmFrame {
    fn from(d: PlcmFrameDto) -> Self {
        Self {
            protocol_version: d.protocol_version,
            session_id: d.session_id,
            frame_id: d.frame_id,
            packet_id: d.packet_id,
            packet_type: packet::PlcmPacketType::from_value(d.packet_type)
                .unwrap_or(packet::PlcmPacketType::Data),
            total_packets: d.total_packets,
            grid_size: d.grid_size,
            bits_per_channel: d.bits_per_channel,
            payload: d.payload,
            checksum: d.checksum,
        }
    }
}

#[frb]
pub struct DataChunkDto {
    pub session_id: String,
    pub chunk_id: u32,
    pub total_chunks: u32,
    pub payload: Vec<u8>,
}

impl From<DataChunk> for DataChunkDto {
    fn from(c: DataChunk) -> Self {
        Self {
            session_id: c.session_id,
            chunk_id: c.chunk_id,
            total_chunks: c.total_chunks,
            payload: c.payload,
        }
    }
}

impl From<DataChunkDto> for DataChunk {
    fn from(d: DataChunkDto) -> Self {
        Self {
            session_id: d.session_id,
            chunk_id: d.chunk_id,
            total_chunks: d.total_chunks,
            payload: d.payload,
        }
    }
}

#[frb]
pub struct CompressionOutputDto {
    pub original_size: u32,
    pub output_size: u32,
    pub bytes: Vec<u8>,
}

impl From<CompressionOutput> for CompressionOutputDto {
    fn from(o: CompressionOutput) -> Self {
        Self {
            original_size: o.original_size as u32,
            output_size: o.output_size as u32,
            bytes: o.bytes,
        }
    }
}

#[frb(opaque)]
pub struct ReconstructionHandle {
    pub(crate) inner: ReconstructionState,
}

#[frb]
impl ReconstructionHandle {
    pub fn set_metadata(&mut self, session_id: String, total_chunks: u32) -> bool {
        self.inner.set_metadata(&session_id, total_chunks)
    }

    pub fn ingest_data(&mut self, chunk: DataChunkDto) -> bool {
        self.inner.ingest_data(chunk.into())
    }

    pub fn is_complete(&self) -> bool {
        self.inner.is_complete()
    }

    pub fn rebuild(&self) -> Option<Vec<u8>> {
        self.inner.rebuild().ok().flatten()
    }

    pub fn reset(&mut self) {
        self.inner.reset();
    }
}

fn parse_compression_kind(kind: &str) -> CoreResult<CompressionKind> {
    match kind {
        "none" => Ok(CompressionKind::None),
        "gzip" => Ok(CompressionKind::Gzip),
        "lz4" => Ok(CompressionKind::Lz4),
        _ => Err(CoreError::InvalidInput(format!("unknown compression: {kind}"))),
    }
}
