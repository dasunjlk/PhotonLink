use std::io::{Read, Write};

use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use flate2::Compression;
use lz4_flex::block::{compress_prepend_size, decompress_size_prepended};

use crate::error::{CoreError, CoreResult};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CompressionKind {
    None,
    Gzip,
    Lz4,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CompressionOutput {
    pub original_size: usize,
    pub output_size: usize,
    pub bytes: Vec<u8>,
}

pub fn compress(input: &[u8], kind: CompressionKind) -> CoreResult<CompressionOutput> {
    match kind {
        CompressionKind::None => Ok(CompressionOutput {
            original_size: input.len(),
            output_size: input.len(),
            bytes: input.to_vec(),
        }),
        CompressionKind::Gzip => {
            let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
            encoder
                .write_all(input)
                .map_err(|e| CoreError::CompressionFailed(e.to_string()))?;
            let bytes = encoder
                .finish()
                .map_err(|e| CoreError::CompressionFailed(e.to_string()))?;
            Ok(CompressionOutput {
                original_size: input.len(),
                output_size: bytes.len(),
                bytes,
            })
        }
        CompressionKind::Lz4 => {
            let bytes = compress_prepend_size(input);
            Ok(CompressionOutput {
                original_size: input.len(),
                output_size: bytes.len(),
                bytes,
            })
        }
    }
}

pub fn decompress(
    input: &[u8],
    kind: CompressionKind,
    original_size: usize,
) -> CoreResult<CompressionOutput> {
    match kind {
        CompressionKind::None => Ok(CompressionOutput {
            original_size,
            output_size: input.len(),
            bytes: input.to_vec(),
        }),
        CompressionKind::Gzip => {
            let mut decoder = GzDecoder::new(input);
            let mut bytes = Vec::new();
            decoder
                .read_to_end(&mut bytes)
                .map_err(|e| CoreError::CompressionFailed(e.to_string()))?;
            Ok(CompressionOutput {
                original_size,
                output_size: bytes.len(),
                bytes,
            })
        }
        CompressionKind::Lz4 => {
            let bytes = decompress_size_prepended(input)
                .map_err(|e| CoreError::CompressionFailed(format!("lz4: {e}")))?;
            Ok(CompressionOutput {
                original_size,
                output_size: bytes.len(),
                bytes,
            })
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn gzip_roundtrip() {
        let data = b"hello world gzip test data".repeat(10);
        let compressed = compress(&data, CompressionKind::Gzip).unwrap();
        let decompressed =
            decompress(&compressed.bytes, CompressionKind::Gzip, data.len()).unwrap();
        assert_eq!(decompressed.bytes, data);
    }

    #[test]
    fn lz4_roundtrip() {
        let data = b"hello world lz4 test data".repeat(10);
        let compressed = compress(&data, CompressionKind::Lz4).unwrap();
        let decompressed =
            decompress(&compressed.bytes, CompressionKind::Lz4, data.len()).unwrap();
        assert_eq!(decompressed.bytes, data);
    }
}
