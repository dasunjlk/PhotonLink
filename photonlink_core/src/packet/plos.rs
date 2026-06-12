use crate::error::{CoreError, CoreResult};
use crate::protocol::{crc32, read_u32_be, uint32_be};

pub const PLOS_MAGIC: &[u8] = b"PLOS";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlosPacketType {
    Metadata = 0,
    Data = 1,
    Parity = 2,
}

impl PlosPacketType {
    pub fn from_value(v: u8) -> Option<Self> {
        match v {
            0 => Some(Self::Metadata),
            1 => Some(Self::Data),
            2 => Some(Self::Parity),
            _ => None,
        }
    }

    pub fn value(self) -> u8 {
        self as u8
    }
}

/// Parsed PLOS binary frame.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlosFrame {
    pub protocol_version: u8,
    pub session_id: String,
    pub stream_id: u16,
    pub frame_id: u32,
    pub packet_id: u32,
    pub packet_type: PlosPacketType,
    pub total_packets: u32,
    pub sync_marker: u16,
    pub timestamp: u64,
    pub grid_size: u32,
    pub bits_per_cell: u8,
    pub payload: Vec<u8>,
    pub checksum: u32,
}

fn read_u16_be(bytes: &[u8], offset: &mut usize) -> Option<u16> {
    if *offset + 2 > bytes.len() {
        return None;
    }
    let v = (bytes[*offset] as u16) << 8 | bytes[*offset + 1] as u16;
    *offset += 2;
    Some(v)
}

fn read_u64_be(bytes: &[u8], offset: &mut usize) -> Option<u64> {
    if *offset + 8 > bytes.len() {
        return None;
    }
    let mut v: u64 = 0;
    for i in 0..8 {
        v = (v << 8) | bytes[*offset + i] as u64;
    }
    *offset += 8;
    Some(v)
}

fn uint16_be(value: u16) -> [u8; 2] {
    [(value >> 8) as u8, value as u8]
}

fn uint64_be(value: u64) -> [u8; 8] {
    [
        (value >> 56) as u8,
        (value >> 48) as u8,
        (value >> 40) as u8,
        (value >> 32) as u8,
        (value >> 24) as u8,
        (value >> 16) as u8,
        (value >> 8) as u8,
        value as u8,
    ]
}

/// Serializes a PLOS frame with trailing CRC32 (matches Dart OpticalStreamSerializer).
pub fn encode_plos_frame(frame: &PlosFrame) -> CoreResult<Vec<u8>> {
    let session_bytes = frame.session_id.as_bytes();
    if session_bytes.len() > 255 {
        return Err(CoreError::InvalidInput("sessionId too long".into()));
    }

    let mut body = Vec::new();
    body.extend_from_slice(PLOS_MAGIC);
    body.push(frame.protocol_version);
    body.push(frame.packet_type.value());
    body.push(session_bytes.len() as u8);
    body.extend_from_slice(session_bytes);
    body.extend_from_slice(&uint16_be(frame.stream_id));
    body.extend_from_slice(&uint32_be(frame.frame_id));
    body.extend_from_slice(&uint32_be(frame.packet_id));
    body.extend_from_slice(&uint32_be(frame.total_packets));
    body.extend_from_slice(&uint16_be(frame.sync_marker));
    body.extend_from_slice(&uint64_be(frame.timestamp));
    body.extend_from_slice(&uint32_be(frame.grid_size));
    body.push(frame.bits_per_cell);
    body.extend_from_slice(&uint32_be(frame.payload.len() as u32));
    body.extend_from_slice(&frame.payload);

    let checksum = crc32(&body);
    body.extend_from_slice(&uint32_be(checksum));
    Ok(body)
}

/// Deserializes a PLOS frame, validating CRC32.
pub fn decode_plos_frame(bytes: &[u8]) -> CoreResult<PlosFrame> {
    if bytes.len() < 32 {
        return Err(CoreError::DecodeFailed("frame too short".into()));
    }
    if &bytes[0..4] != PLOS_MAGIC {
        return Err(CoreError::DecodeFailed("bad magic".into()));
    }

    let mut offset = 4;
    let protocol_version = bytes[offset];
    offset += 1;
    let packet_type = PlosPacketType::from_value(bytes[offset])
        .ok_or_else(|| CoreError::DecodeFailed("invalid packet type".into()))?;
    offset += 1;
    let session_len = bytes[offset] as usize;
    offset += 1;
    if offset + session_len > bytes.len() {
        return Err(CoreError::DecodeFailed("truncated sessionId".into()));
    }
    let session_id = std::str::from_utf8(&bytes[offset..offset + session_len])
        .map_err(|e| CoreError::DecodeFailed(format!("sessionId utf8: {e}")))?
        .to_string();
    offset += session_len;

    let stream_id = read_u16_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated streamId".into()))?;
    let frame_id = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated frameId".into()))?;
    let packet_id = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated packetId".into()))?;
    let total_packets = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated totalPackets".into()))?;
    let sync_marker = read_u16_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated syncMarker".into()))?;
    let timestamp = read_u64_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated timestamp".into()))?;
    let grid_size = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated gridSize".into()))?;
    if offset >= bytes.len() {
        return Err(CoreError::DecodeFailed("truncated bitsPerCell".into()));
    }
    let bits_per_cell = bytes[offset];
    offset += 1;
    let payload_len = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated payloadLen".into()))? as usize;
    if offset + payload_len + 4 > bytes.len() {
        return Err(CoreError::DecodeFailed("truncated payload".into()));
    }
    let payload = bytes[offset..offset + payload_len].to_vec();
    offset += payload_len;
    let checksum = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated checksum".into()))?;

    let body = &bytes[..offset - 4];
    if crc32(body) != checksum {
        return Err(CoreError::ChecksumMismatch);
    }

    Ok(PlosFrame {
        protocol_version,
        session_id,
        stream_id,
        frame_id,
        packet_id,
        packet_type,
        total_packets,
        sync_marker,
        timestamp,
        grid_size,
        bits_per_cell,
        payload,
        checksum,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plos_roundtrip() {
        let frame = PlosFrame {
            protocol_version: 1,
            session_id: "test-session".into(),
            stream_id: 1,
            frame_id: 42,
            packet_id: 7,
            packet_type: PlosPacketType::Data,
            total_packets: 10,
            sync_marker: 0xA55A,
            timestamp: 1_700_000_000_000,
            grid_size: 24,
            bits_per_cell: 1,
            payload: vec![1, 2, 3, 4, 5],
            checksum: 0,
        };

        let encoded = encode_plos_frame(&frame).unwrap();
        let decoded = decode_plos_frame(&encoded).unwrap();
        assert_eq!(decoded.session_id, "test-session");
        assert_eq!(decoded.frame_id, 42);
        assert_eq!(decoded.packet_id, 7);
        assert_eq!(decoded.payload, vec![1, 2, 3, 4, 5]);
        assert_eq!(decoded.sync_marker, 0xA55A);
    }
}
