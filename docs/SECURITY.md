# PhotonLink Phase 4 — Security Review

## Encryption

- **Algorithm:** ChaCha20-Poly1305 (AEAD) via `cryptography` package
- **Scope:** Whole wire payload after compression, before chunking
- **Session key:** 256-bit random, delivered in `SessionSetupPacket` (base64) over setup QR

## Key lifecycle

| Stage | Behavior |
|-------|----------|
| Generation | Sender `SessionKeyExchange.generateForSender()` |
| Delivery | Setup QR frame (`PL2|S|...`) |
| Storage | `EncryptionKeyProvider` in memory for session |
| Clear | `clear()` zeroes buffer on complete/fail/reset |

## Limitations (known)

1. **Key in QR:** Session key is visible to anyone who can scan the setup QR (simplified exchange; future X25519/ECDH planned).
2. **No forward secrecy:** Single static session key per transfer.
3. **Replay:** No explicit anti-replay nonces at protocol level; chunk IDs + session ID limit naive replay within a session.
4. **Tampering:** AEAD tag rejects modified ciphertext; wire SHA-256 verified before decrypt.
5. **Spoofing:** No device authentication; metadata/sessionId are not signed.
6. **Memory:** Keys held in Dart heap; not hardened against forensic extraction.

## Recommendations for production

- Replace setup-QR key delivery with ECDH (X25519) + authenticated pairing
- Add user-visible pairing code or out-of-band secret
- Consider per-chunk AEAD with derived subkeys for streaming
