// ===============================================================================
// RustFoundry OS:
// Developer-first OS built in Rust, including console-only "Bare Metal Edition".
// Copyright (C) 2025 XalorTech
// License: GPLv3 (see LICENSE.md for details)
// ===============================================================================

// Purpose:
//   Minimal UEFI AArch64 entry veneer (PE/COFF) that:
//     - Sets a small private bootstrap stack.
//     - Ensures 16-byte stack alignment per AAPCS64.
//     - Forwards UEFI entry arguments (x0 = ImageHandle, x1 = SystemTable).
//     - Branches to Rust (bootloader_stage0) and never returns.
//
// Tooling:
//   - Assemble with clang into a COFF ARM64 object:
//       clang -c -target aarch64-windows -o entry_arm64.obj entry.S
//   - Link with lld-link via Cargo (see build.rs).

	.text
	.align		4
	.global		_start
	.extern		bootloader_stage0

_start:
	// Set a private bootstrap stack (UEFI provides one; we prefer determinism).
	adrp		sp, stack_top@PAGE
	add			sp, sp, stack_top@PAGEOFF
	// AAPCS64 mandates 16-byte stack alignment at call sites; stack_top is aligned.

	// UEFI passes:
	//   x0 = EFI_IMAGE_HANDLE, x1 = EFI_SYSTEM_TABLE*
	// Forward x0,x1 unchanged to Rust.
	bl			bootloader_stage0

1:	wfe
	b			1b

	.section	.bss, "aw", %nobits
	.align		4
	.global		stack_area
	.global		stack_top

stack_area:
	.space		4096						// 4 KiB bootstrap stack
stack_top:
