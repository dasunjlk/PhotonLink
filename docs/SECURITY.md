# PhotonLink Security Review (Phase 4–5)

## Encryption

- **Algorithm:** ChaCha20-Poly1305 (AEAD) via `cryptography` package
- **Scope:** Whole wire payload after compression, before chunking
- **Session key:** 256-bit random (`SessionKeyExchange`)

## Key delivery by transport

| Transport | Key delivery | Notes |
|-----------|--------------|-------|
| **QR** | `SessionSetupPacket` in setup QR (`PL2|S|...`) | Receiver scans setup before metadata when encryption enabled |
| **Color Matrix** | `keyExchangePayload` in metadata JSON | No separate setup frame; key re-broadcast with metadata each loop |

In both cases the session key is **visible on the optical channel** (base64 in frame payload). This is a simplified exchange; future X25519/ECDH is planned.

## Key lifecycle

| Stage | Behavior |
|-------|----------|
| Generation | Sender `SessionKeyExchange.generateForSender()` |
| Storage | `EncryptionKeyProvider` in memory for session |
| Clear | `clear()` zeroes buffer on complete/fail/reset (QR and Color Matrix receivers) |

## Integrity verification

| Transport | Wire SHA-256 before decrypt | Plaintext SHA-256 after decrypt | Fail closed |
|-----------|----------------------------|--------------------------------|-------------|
| QR | Yes | Yes | Yes |
| Color Matrix | Yes | Yes | Yes |

## Limitations (known)

1. **Key on optical channel:** Session key is visible to anyone who can capture setup/metadata frames.
2. **No forward secrecy:** Single static session key per transfer.
3. **Replay:** No explicit anti-replay nonces at protocol level; chunk IDs + session ID limit naive replay within a session.
4. **Tampering:** AEAD tag rejects modified ciphertext; wire SHA-256 verified before decrypt.
5. **Spoofing:** No device authentication; metadata/sessionId are not signed.
6. **Memory:** Keys held in Dart heap; not hardened against forensic extraction.
7. **Resume:** Persisted sessions do not store encryption keys; encrypted resume after app restart is not supported.

## Recommendations for production

- Replace plaintext key delivery with ECDH (X25519) + authenticated pairing
- Add user-visible pairing code or out-of-band secret
- Consider per-chunk AEAD with derived subkeys for streaming
- Store transform metadata + key material securely for resume (or require re-scan of setup)
