; ===============================================================================
; RustFoundry OS:
; Developer-first OS built in Rust, including console-only "Bare Metal Edition".
; Copyright (C) 2025 XalorTech
; License: GPLv3 (see LICENSE.md for details)
; ===============================================================================

; Purpose:
;   Tiny UEFI x86_64 entry veneer that:
;     - Establishes a known-good stack (even though UEFI provides one).
;     - Ensures 16-byte stack alignment before calling into Rust.
;     - Tail-calls a Rust function that performs all subsequent bootloader work.
;
; Design notes:
;   - Targeting NASM "win64 COFF" object output for linkage into a PE/COFF .efi.
;   - We do not perform any firmware calls here; keep this veneer minimal.
;   - We do not clobber callee-saved registers unnecessarily.
;
; Linkage expectations:
;   - The bootloader crate’s linker args must set /ENTRY:_start (lld-link) or
;     the equivalent, so this symbol is used as the PE/COFF entry point.
;   - The Rust side provides: extern "C" fn bootloader_stage0() -> !
;     with #[no_mangle] so the symbol name is exactly "bootloader_stage0".

; ----------------------------
; Section layout
; ----------------------------
default		rel

section		.text align=16
global		_start

; ----------------------------
; Symbols for the private stack
; ----------------------------
extern		bootloader_stage0

_start:
	; Establish a known-good stack.
	; UEFI typically provides a valid stack, but we opt into our own tiny,
	; private bootstrap stack to keep early behavior deterministic.
	lea			rsp, [stack_top]

	; System V AMD64 ABI requires 16-byte alignment at call boundaries.
	; Align down to 16 just in case the address isn’t already aligned.
	and			rsp, -16

	; Clear rbx (callee-saved). Not strictly required, but avoids carrying
	; garbage from firmware into our first frame.
	xor			rbx, rbx

	; Call into Rust stage 0. This function never returns (-> !).
	; We avoid passing firmware handles here to keep the veneer arch-minimal.
	call		bootloader_stage0

.hang:
	hlt
	jmp			.hang

; ----------------------------
; Bootstrap stack (one page)
; ----------------------------
section		.bss align=16
global		stack_area
global		stack_top

stack_area:
	; One 4 KiB page for early use. The Rust side may later switch to
	; a larger, allocator-backed stack if desired.
	resb		4096
stack_top:
