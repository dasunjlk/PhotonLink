pub mod crc32;

pub use crc32::{crc32, validate_crc32};

/// Encode a u32 as big-endian bytes.
pub fn uint32_be(value: u32) -> [u8; 4] {
    value.to_be_bytes()
}

/// Decode big-endian u32 from slice.
pub fn read_u32_be(bytes: &[u8], offset: &mut usize) -> Option<u32> {
    if *offset + 4 > bytes.len() {
        return None;
    }
    let v = u32::from_be_bytes([
        bytes[*offset],
        bytes[*offset + 1],
        bytes[*offset + 2],
        bytes[*offset + 3],
    ]);
    *offset += 4;
    Some(v)
}
