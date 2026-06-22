//! PhotonLink Rust core engine (Phase 8).
//!
//! Performance-critical transfer logic: hashing, checksums, packet codecs,
//! chunking, reconstruction, compression, encryption, diagnostics, and FEC.

mod frb_generated;

pub mod api;
pub mod chunking;
pub mod compression;
pub mod diagnostics;
pub mod encryption;
pub mod error;
pub mod fec;
pub mod hashing;
pub mod packet;
pub mod protocol;
pub mod reconstruction;

pub use error::CoreError;

/// Returns the core engine version string.
pub fn core_version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn core_version_is_non_empty() {
        assert!(!core_version().is_empty());
    }
}
