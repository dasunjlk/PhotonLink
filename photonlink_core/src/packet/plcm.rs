use crate::error::{CoreError, CoreResult};
use crate::protocol::{crc32, read_u32_be, uint32_be};

pub const PLCM_MAGIC: &[u8] = b"PLCM";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlcmPacketType {
    Metadata = 0,
    Data = 1,
    Parity = 2,
}

impl PlcmPacketType {
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

/// Parsed PLCM binary frame.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlcmFrame {
    pub protocol_version: u8,
    pub session_id: String,
    pub frame_id: u32,
    pub packet_id: u32,
    pub packet_type: PlcmPacketType,
    pub total_packets: u32,
    pub grid_size: u32,
    pub bits_per_channel: u8,
    pub payload: Vec<u8>,
    pub checksum: u32,
}

/// Serializes a PLCM frame with trailing CRC32 (matches Dart ColorMatrixSerializer).
pub fn encode_plcm_frame(frame: &PlcmFrame) -> CoreResult<Vec<u8>> {
    let session_bytes = frame.session_id.as_bytes();
    if session_bytes.len() > 255 {
        return Err(CoreError::InvalidInput("sessionId too long".into()));
    }

    let mut body = Vec::new();
    body.extend_from_slice(PLCM_MAGIC);
    body.push(frame.protocol_version);
    body.push(frame.packet_type.value());
    body.push(session_bytes.len() as u8);
    body.extend_from_slice(session_bytes);
    body.extend_from_slice(&uint32_be(frame.frame_id));
    body.extend_from_slice(&uint32_be(frame.packet_id));
    body.extend_from_slice(&uint32_be(frame.total_packets));
    body.extend_from_slice(&uint32_be(frame.grid_size));
    body.push(frame.bits_per_channel);
    body.extend_from_slice(&uint32_be(frame.payload.len() as u32));
    body.extend_from_slice(&frame.payload);

    let checksum = crc32(&body);
    body.extend_from_slice(&uint32_be(checksum));
    Ok(body)
}

/// Deserializes a PLCM frame, validating CRC32.
pub fn decode_plcm_frame(bytes: &[u8]) -> CoreResult<PlcmFrame> {
    if bytes.len() < 24 {
        return Err(CoreError::DecodeFailed("frame too short".into()));
    }
    if &bytes[0..4] != PLCM_MAGIC {
        return Err(CoreError::DecodeFailed("bad magic".into()));
    }

    let mut offset = 4;
    let protocol_version = bytes[offset];
    offset += 1;
    let packet_type = PlcmPacketType::from_value(bytes[offset])
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

    let frame_id = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated frameId".into()))?;
    let packet_id = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated packetId".into()))?;
    let total_packets = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated totalPackets".into()))?;
    let grid_size = read_u32_be(bytes, &mut offset)
        .ok_or_else(|| CoreError::DecodeFailed("truncated gridSize".into()))?;
    if offset >= bytes.len() {
        return Err(CoreError::DecodeFailed("truncated bitsPerChannel".into()));
    }
    let bits_per_channel = bytes[offset];
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

    Ok(PlcmFrame {
        protocol_version,
        session_id,
        frame_id,
        packet_id,
        packet_type,
        total_packets,
        grid_size,
        bits_per_channel,
        payload,
        checksum,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plcm_roundtrip() {
        let frame = PlcmFrame {
            protocol_version: 1,
            session_id: "test-session".to_string(),
            frame_id: 1,
            packet_id: 0,
            packet_type: PlcmPacketType::Data,
            total_packets: 5,
            grid_size: 16,
            bits_per_channel: 2,
            payload: vec![1, 2, 3, 4],
            checksum: 0,
        };
        let encoded = encode_plcm_frame(&frame).unwrap();
        let decoded = decode_plcm_frame(&encoded).unwrap();
        assert_eq!(decoded.session_id, frame.session_id);
        assert_eq!(decoded.payload, frame.payload);
    }
}
