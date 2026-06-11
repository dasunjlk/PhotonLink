use sha2::{Digest, Sha256};

/// Computes SHA-256 hash as lowercase hex string (matches Dart `crypto` output).
pub fn sha256_hex(data: &[u8]) -> String {
    let digest = Sha256::digest(data);
    digest.iter().map(|b| format!("{b:02x}")).collect()
}

/// Validates data against an expected hex SHA-256 hash (case-insensitive).
pub fn sha256_verify(data: &[u8], expected: &str) -> bool {
    sha256_hex(data).eq_ignore_ascii_case(expected)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_data_hash() {
        assert_eq!(
            sha256_hex(b""),
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
    }

    #[test]
    fn hello_hash() {
        assert_eq!(
            sha256_hex(b"hello"),
            "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        );
    }
}
