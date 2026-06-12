/// CRC32 reflected IEEE (poly 0xEDB88320) — matches Dart ColorMatrixSerializer.
pub fn crc32(data: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFF_FFFF;
    for &byte in data {
        crc ^= u32::from(byte);
        for _ in 0..8 {
            if crc & 1 != 0 {
                crc = (crc >> 1) ^ 0xEDB8_8320;
            } else {
                crc >>= 1;
            }
        }
    }
    (!crc) & 0xFFFF_FFFF
}

pub fn validate_crc32(data: &[u8], expected: u32) -> bool {
    crc32(data) == expected
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_crc() {
        assert_eq!(crc32(b""), 0);
    }

    #[test]
    fn hello_crc() {
        assert_eq!(crc32(b"hello"), 0x3610_a686);
    }
}
