/// FEC configuration matching Dart FecConfiguration.
#[derive(Debug, Clone)]
pub struct FecConfig {
    pub enabled: bool,
    pub redundancy_percent: u32,
    pub block_size: u32,
}

impl Default for FecConfig {
    fn default() -> Self {
        Self {
            enabled: false,
            redundancy_percent: 10,
            block_size: 10,
        }
    }
}

impl FecConfig {
    pub fn parity_count_for_block(&self, data_count: u32) -> u32 {
        if !self.enabled || data_count < 1 {
            return 0;
        }
        let percent = self.redundancy_percent;
        let raw = ((data_count as f64 * percent as f64 / 100.0).ceil()) as u32;
        raw.clamp(1, 255 - data_count)
    }
}

/// Describes a single FEC block.
#[derive(Debug, Clone)]
pub struct FecBlockPlan {
    pub block_index: u32,
    pub data_chunk_ids: Vec<u32>,
    pub data_count: u32,
    pub parity_count: u32,
    pub symbol_length: u32,
    pub first_parity_id: u32,
}

pub fn plan_blocks(total_chunks: u32, config: &FecConfig, symbol_length: u32) -> Vec<FecBlockPlan> {
    if total_chunks < 1 || !config.enabled {
        return vec![];
    }

    let mut plans = Vec::new();
    let mut block_index = 0u32;
    let mut parity_id = 0u32;
    let mut offset = 0u32;

    while offset < total_chunks {
        let end = std::cmp::min(offset + config.block_size, total_chunks);
        let chunk_ids: Vec<u32> = (offset..end).collect();
        let k = chunk_ids.len() as u32;
        let m = config.parity_count_for_block(k);
        if m < 1 {
            offset = end;
            continue;
        }

        plans.push(FecBlockPlan {
            block_index,
            data_chunk_ids: chunk_ids,
            data_count: k,
            parity_count: m,
            symbol_length,
            first_parity_id: parity_id,
        });

        parity_id += m;
        block_index += 1;
        offset = end;
    }

    plans
}

pub fn pad_payload(payload: &[u8], symbol_length: usize) -> Vec<u8> {
    if payload.len() == symbol_length {
        return payload.to_vec();
    }
    if payload.len() > symbol_length {
        return payload[..symbol_length].to_vec();
    }
    let mut padded = vec![0u8; symbol_length];
    padded[..payload.len()].copy_from_slice(payload);
    padded
}

pub fn trim_payload(padded: &[u8], original_length: usize) -> Vec<u8> {
    if padded.len() == original_length {
        return padded.to_vec();
    }
    padded[..original_length].to_vec()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plan_blocks_basic() {
        let config = FecConfig {
            enabled: true,
            redundancy_percent: 10,
            block_size: 10,
        };
        let plans = plan_blocks(25, &config, 512);
        assert_eq!(plans.len(), 3);
        assert_eq!(plans[0].data_count, 10);
        assert_eq!(plans[2].data_count, 5);
    }
}
