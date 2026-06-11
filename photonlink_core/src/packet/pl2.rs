use base64::{engine::general_purpose::STANDARD, Engine};
use crate::error::{CoreError, CoreResult};

pub const PL2_MAGIC: &str = "PL2";

/// Parsed PL2 wire frame.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pl2Frame {
    pub packet_type: char,
    pub session_id: String,
    pub seq: u32,
    pub total: u32,
    pub payload: Vec<u8>,
}

/// Encodes a PL2 data frame: `PL2|D|<sessionId>|<chunkId>|<totalChunks>|<base64>`.
pub fn encode_pl2_data_frame(
    session_id: &str,
    chunk_id: u32,
    total_chunks: u32,
    payload: &[u8],
) -> CoreResult<String> {
    validate_session_id(session_id)?;
    let b64 = STANDARD.encode(payload);
    Ok(format!(
        "{PL2_MAGIC}|D|{session_id}|{chunk_id}|{total_chunks}|{b64}"
    ))
}

/// Decodes any PL2 frame string.
pub fn decode_pl2_frame(raw: &str) -> CoreResult<Pl2Frame> {
    if !raw.starts_with(&format!("{PL2_MAGIC}|")) {
        return Err(CoreError::DecodeFailed("missing PL2 magic".into()));
    }

    let parts: Vec<&str> = raw.split('|').collect();
    if parts.len() != 6 {
        return Err(CoreError::DecodeFailed(format!(
            "expected 6 fields, got {}",
            parts.len()
        )));
    }

    let packet_type = parts[1]
        .chars()
        .next()
        .ok_or_else(|| CoreError::DecodeFailed("empty type".into()))?;

    let session_id = parts[2].to_string();
    validate_session_id(&session_id)?;

    let seq: u32 = parts[3]
        .parse()
        .map_err(|_| CoreError::DecodeFailed("invalid seq".into()))?;
    let total: u32 = parts[4]
        .parse()
        .map_err(|_| CoreError::DecodeFailed("invalid total".into()))?;

    let payload = if packet_type == 'D' {
        STANDARD
            .decode(parts[5])
            .map_err(|e| CoreError::DecodeFailed(format!("base64: {e}")))?
    } else {
        // JSON payloads for other types are UTF-8 bytes
        parts[5].as_bytes().to_vec()
    };

    Ok(Pl2Frame {
        packet_type,
        session_id,
        seq,
        total,
        payload,
    })
}

fn validate_session_id(session_id: &str) -> CoreResult<()> {
    if session_id.is_empty() || session_id.len() > 128 {
        return Err(CoreError::InvalidInput(
            "sessionId must be 1..=128 chars".into(),
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn data_frame_roundtrip() {
        let payload = b"hello world".to_vec();
        let encoded = encode_pl2_data_frame("sess1", 0, 1, &payload).unwrap();
        let decoded = decode_pl2_frame(&encoded).unwrap();
        assert_eq!(decoded.packet_type, 'D');
        assert_eq!(decoded.payload, payload);
    }
}
