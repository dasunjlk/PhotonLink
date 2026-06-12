use std::collections::HashMap;

use crate::chunking::{merge, DataChunk};
use crate::error::{CoreError, CoreResult};

/// Metadata required for reconstruction.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MetadataInfo {
    pub session_id: String,
    pub total_chunks: u32,
}

/// Stateful reconstruction engine (matches Dart ReconstructionEngine).
#[derive(Debug, Default)]
pub struct ReconstructionState {
    metadata: Option<MetadataInfo>,
    chunks: HashMap<u32, DataChunk>,
}

impl ReconstructionState {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn has_metadata(&self) -> bool {
        self.metadata.is_some()
    }

    pub fn received_count(&self) -> usize {
        self.chunks.len()
    }

    pub fn total_chunks(&self) -> u32 {
        self.metadata.as_ref().map(|m| m.total_chunks).unwrap_or(0)
    }

    pub fn is_complete(&self) -> bool {
        let Some(meta) = &self.metadata else {
            return false;
        };
        if meta.total_chunks < 1 {
            return false;
        }
        if self.chunks.len() != meta.total_chunks as usize {
            return false;
        }
        (0..meta.total_chunks).all(|i| self.chunks.contains_key(&i))
    }

    pub fn progress(&self) -> f64 {
        match &self.metadata {
            Some(m) if m.total_chunks > 0 => self.chunks.len() as f64 / m.total_chunks as f64,
            _ => 0.0,
        }
    }

    pub fn received_chunk_ids(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.chunks.keys().copied().collect();
        ids.sort_unstable();
        ids
    }

    pub fn set_metadata(&mut self, session_id: &str, total_chunks: u32) -> bool {
        if let Some(existing) = &self.metadata {
            if existing.session_id != session_id {
                self.reset();
            }
        } else {
            self.chunks.clear();
        }
        self.metadata = Some(MetadataInfo {
            session_id: session_id.to_string(),
            total_chunks,
        });
        true
    }

    pub fn ingest_data(&mut self, chunk: DataChunk) -> bool {
        let Some(meta) = &self.metadata else {
            return false;
        };
        if chunk.session_id != meta.session_id {
            return false;
        }
        if chunk.total_chunks != meta.total_chunks {
            return false;
        }
        if chunk.chunk_id >= meta.total_chunks {
            return false;
        }
        if self.chunks.contains_key(&chunk.chunk_id) {
            return false;
        }
        self.chunks.insert(chunk.chunk_id, chunk);
        true
    }

    pub fn inject_recovered(&mut self, chunk: DataChunk) -> bool {
        self.ingest_data(chunk)
    }

    pub fn export_received_data(&self) -> HashMap<u32, DataChunk> {
        self.chunks.clone()
    }

    pub fn rebuild(&self) -> CoreResult<Option<Vec<u8>>> {
        if !self.is_complete() {
            return Ok(None);
        }
        let meta = self.metadata.as_ref().unwrap();
        let mut ordered: Vec<DataChunk> = (0..meta.total_chunks)
            .map(|i| {
                self.chunks
                    .get(&i)
                    .cloned()
                    .ok_or_else(|| CoreError::DecodeFailed(format!("missing chunk {i}")))
            })
            .collect::<CoreResult<Vec<_>>>()?;
        Ok(Some(merge(&mut ordered)?))
    }

    pub fn reset(&mut self) {
        self.metadata = None;
        self.chunks.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::chunking::split;

    #[test]
    fn complete_rebuild() {
        let data: Vec<u8> = (0..100).collect();
        let chunks = split(&data, "s1", 30).unwrap();
        let mut state = ReconstructionState::new();
        state.set_metadata("s1", chunks.len() as u32);
        for c in &chunks {
            assert!(state.ingest_data(c.clone()));
        }
        assert!(state.is_complete());
        assert_eq!(state.rebuild().unwrap().unwrap(), data);
    }
}
