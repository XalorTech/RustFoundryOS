// ===============================================================================
// RustFoundry OS:
// Developer-first OS built in Rust, including console-only "Bare Metal Edition".
// Copyright (C) 2025 XalorTech
// License: GPLv3 (see LICENSE.md for details)
// ===============================================================================

#![no_std]
#![no_main]

use core::ffi::c_void;
use core::panic::PanicInfo;

/// Architecture-specific CPU halt/idle instruction.
#[cfg(target_arch = "x86_64")]
#[inline(always)]
fn halt() {
	unsafe { core::arch::asm!("hlt", options(nomem, nostack, preserves_flags)); }
}

#[cfg(target_arch = "aarch64")]
#[inline(always)]
fn halt() {
	// Use WFE (Wait For Event) as a safe idle instruction in early boot.
	unsafe { core::arch::asm!("wfe", options(nomem, nostack, preserves_flags)); }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
	loop { halt(); }
}

// Stage-0 entry from the veneer.
// UEFI passes the image handle and system table pointer; we keep them typed-opaque for now.
#[unsafe(no_mangle)]
pub extern "C" fn bootloader_stage0(image_handle: usize, system_table: *mut c_void) -> ! {
	let _ = (image_handle, system_table); // placeholders for now

	// TDD seam: we'll print a deterministic line via UEFI next.
	loop { halt(); }
}
