use std::panic::{catch_unwind, AssertUnwindSafe};
use thiserror::Error;

/// Unified error type for the Rust core engine.
#[derive(Debug, Error, Clone, PartialEq, Eq)]
pub enum CoreError {
    #[error("invalid input: {0}")]
    InvalidInput(String),
    #[error("checksum mismatch")]
    ChecksumMismatch,
    #[error("decode failed: {0}")]
    DecodeFailed(String),
    #[error("encode failed: {0}")]
    EncodeFailed(String),
    #[error("recovery failed: {0}")]
    RecoveryFailed(String),
    #[error("compression failed: {0}")]
    CompressionFailed(String),
    #[error("encryption failed: {0}")]
    EncryptionFailed(String),
    #[error("internal panic: {0}")]
    InternalPanic(String),
}

pub type CoreResult<T> = Result<T, CoreError>;

/// Wraps a fallible closure, catching panics and mapping to [CoreError].
pub fn catch_core<F, T>(f: F) -> CoreResult<T>
where
    F: FnOnce() -> CoreResult<T>,
{
    match catch_unwind(AssertUnwindSafe(f)) {
        Ok(result) => result,
        Err(payload) => {
            let msg = if let Some(s) = payload.downcast_ref::<&str>() {
                (*s).to_string()
            } else if let Some(s) = payload.downcast_ref::<String>() {
                s.clone()
            } else {
                "unknown panic".to_string()
            };
            Err(CoreError::InternalPanic(msg))
        }
    }
}
