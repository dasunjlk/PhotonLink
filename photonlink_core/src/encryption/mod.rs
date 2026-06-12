use chacha20poly1305::aead::{Aead, KeyInit, OsRng};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use rand::RngCore;
use zeroize::Zeroize;

use crate::error::{CoreError, CoreResult};

const NONCE_LEN: usize = 12;
const MAC_LEN: usize = 16;

/// Encrypts plaintext with ChaCha20-Poly1305.
/// Wire format: nonce(12) + mac(16) + ciphertext — matches Dart EncryptedPayload.
pub fn encrypt(plaintext: &[u8], session_key: &[u8]) -> CoreResult<Vec<u8>> {
    if session_key.len() != 32 {
        return Err(CoreError::EncryptionFailed(
            "session key must be 32 bytes".into(),
        ));
    }

    let cipher = ChaCha20Poly1305::new_from_slice(session_key)
        .map_err(|e| CoreError::EncryptionFailed(e.to_string()))?;

    let mut nonce_bytes = [0u8; NONCE_LEN];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| CoreError::EncryptionFailed(e.to_string()))?;

    // chacha20poly1305 returns ciphertext || tag
    if ciphertext.len() < MAC_LEN {
        return Err(CoreError::EncryptionFailed("ciphertext too short".into()));
    }
    let ct_len = ciphertext.len() - MAC_LEN;
    let (ct, tag) = ciphertext.split_at(ct_len);

    let mut wire = Vec::with_capacity(NONCE_LEN + MAC_LEN + ct.len());
    wire.extend_from_slice(&nonce_bytes);
    wire.extend_from_slice(tag);
    wire.extend_from_slice(ct);
    Ok(wire)
}

/// Decrypts wire bytes (nonce + mac + ciphertext).
pub fn decrypt(wire: &[u8], session_key: &[u8]) -> CoreResult<Vec<u8>> {
    if session_key.len() != 32 {
        return Err(CoreError::EncryptionFailed(
            "session key must be 32 bytes".into(),
        ));
    }
    if wire.len() < NONCE_LEN + MAC_LEN {
        return Err(CoreError::EncryptionFailed("wire too short".into()));
    }

    let nonce = Nonce::from_slice(&wire[..NONCE_LEN]);
    let mac = &wire[NONCE_LEN..NONCE_LEN + MAC_LEN];
    let ciphertext = &wire[NONCE_LEN + MAC_LEN..];

    let mut ct_with_tag = Vec::with_capacity(ciphertext.len() + MAC_LEN);
    ct_with_tag.extend_from_slice(ciphertext);
    ct_with_tag.extend_from_slice(mac);

    let cipher = ChaCha20Poly1305::new_from_slice(session_key)
        .map_err(|e| CoreError::EncryptionFailed(e.to_string()))?;

    let plaintext = cipher
        .decrypt(nonce, ct_with_tag.as_ref())
        .map_err(|e| CoreError::EncryptionFailed(e.to_string()))?;

    ct_with_tag.zeroize();
    Ok(plaintext)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encrypt_decrypt_roundtrip() {
        let key = [42u8; 32];
        let plain = b"secret payload data";
        let wire = encrypt(plain, &key).unwrap();
        assert!(wire.len() >= NONCE_LEN + MAC_LEN + plain.len());
        let recovered = decrypt(&wire, &key).unwrap();
        assert_eq!(recovered, plain);
    }
}
