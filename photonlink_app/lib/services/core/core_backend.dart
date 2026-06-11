/// Core backend selection for dual-backend architecture (Phase 8).
enum CoreBackend {
  /// Existing Dart implementations (default — always available).
  dart,

  /// Rust photonlink_core via flutter_rust_bridge (requires toolchain + codegen).
  rust,
}
