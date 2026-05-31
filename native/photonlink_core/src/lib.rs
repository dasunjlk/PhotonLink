//! PhotonLink Rust core engine.
//!
//! Phase 1: trait definitions and version API only.
//! Phase 2: implement optical encoding/decoding and wire via flutter_rust_bridge.

pub mod ffi;
pub mod protocols;

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
