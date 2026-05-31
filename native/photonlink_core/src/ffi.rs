//! FFI skeleton for Phase 2 flutter_rust_bridge integration.
//!
//! Uncomment and adapt when wiring the Rust core to Flutter:
//!
//! ```ignore
//! use std::ffi::{CStr, CString};
//! use std::os::raw::c_char;
//!
//! #[no_mangle]
//! pub extern "C" fn photonlink_core_version() -> *mut c_char {
//!     CString::new(crate::core_version()).unwrap().into_raw()
//! }
//!
//! #[no_mangle]
//! pub extern "C" fn photonlink_free_string(s: *mut c_char) {
//!     unsafe { drop(CString::from_raw(s)); }
//! }
//! ```
