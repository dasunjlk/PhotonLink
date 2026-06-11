use crate::error::{CoreError, CoreResult};

pub const DEFAULT_CHUNK_SIZE: usize = 512;

/// A data chunk produced by the chunking engine.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DataChunk {
    pub session_id: String,
    pub chunk_id: u32,
    pub total_chunks: u32,
    pub payload: Vec<u8>,
}

/// Splits data into fixed-size chunks (matches Dart ChunkingEngine).
pub fn split(
    data: &[u8],
    session_id: &str,
    chunk_size: usize,
) -> CoreResult<Vec<DataChunk>> {
    if chunk_size == 0 {
        return Err(CoreError::InvalidInput("chunk_size must be > 0".into()));
    }

    if data.is_empty() {
        return Ok(vec![DataChunk {
            session_id: session_id.to_string(),
            chunk_id: 0,
            total_chunks: 1,
            payload: vec![],
        }]);
    }

    let total_chunks = data.len().div_ceil(chunk_size) as u32;
    let mut chunks = Vec::with_capacity(total_chunks as usize);

    for i in 0..total_chunks {
        let start = (i as usize) * chunk_size;
        let end = std::cmp::min(start + chunk_size, data.len());
        chunks.push(DataChunk {
            session_id: session_id.to_string(),
            chunk_id: i,
            total_chunks,
            payload: data[start..end].to_vec(),
        });
    }

    Ok(chunks)
}

/// Merges chunks in chunk_id order (matches Dart ChunkingEngine.merge).
pub fn merge(chunks: &mut [DataChunk]) -> CoreResult<Vec<u8>> {
    if chunks.is_empty() {
        return Ok(vec![]);
    }

    chunks.sort_by_key(|c| c.chunk_id);
    let total_len: usize = chunks.iter().map(|c| c.payload.len()).sum();
    let mut result = Vec::with_capacity(total_len);
    for chunk in chunks.iter() {
        result.extend_from_slice(&chunk.payload);
    }
    Ok(result)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_data_single_chunk() {
        let chunks = split(b"", "sess", DEFAULT_CHUNK_SIZE).unwrap();
        assert_eq!(chunks.len(), 1);
        assert_eq!(chunks[0].total_chunks, 1);
        assert!(chunks[0].payload.is_empty());
    }

    #[test]
    fn split_and_merge_roundtrip() {
        let data: Vec<u8> = (0..1200).map(|i| (i % 256) as u8).collect();
        let mut chunks = split(&data, "s1", 512).unwrap();
        assert_eq!(chunks.len(), 3);
        let merged = merge(&mut chunks).unwrap();
        assert_eq!(merged, data);
    }
}
