// ===============================================================================
// RustFoundry OS:
// Developer-first OS built in Rust, including console-only "Bare Metal Edition".
// Copyright (C) 2025 XalorTech
// License: GPLv3 (see LICENSE.md for details)
// ===============================================================================

use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
	let target = env::var("TARGET").unwrap_or_default();
	let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR not set"));

	// Always rebuild if veneers change
	println!("cargo:rerun-if-changed=bootloader/asm/x86_64/entry.asm");
	println!("cargo:rerun-if-changed=bootloader/asm/aarch64/entry.S");

	if target.starts_with("x86_64") {
		let asm = "bootloader/asm/x86_64/entry.asm";
		let obj = out_dir.join("entry_x86_64.obj");

		let status = Command::new("nasm")
			.args(["-f", "win64", "-g", "-o"])
			.arg(&obj)
			.arg(asm)
			.status()
			.expect("failed to spawn nasm");
		if !status.success() {
			panic!("nasm failed for {}", asm);
		}

		// Link the object and set the entry symbol for PE/COFF
		println!("cargo:rustc-link-arg-bins={}", obj.display());
		println!("cargo:rustc-link-arg-bins=/ENTRY:_start");
	} else if target.starts_with("aarch64") {
		let asm = "bootloader/asm/aarch64/entry.S";
		let obj = out_dir.join("entry_aarch64.obj");

		// Use clang to produce a COFF ARM64 object suitable for lld-link
		let status = Command::new("clang")
			.args([
				"-c",
				"-target", "aarch64-windows",
				"-g",
				"-o",
			])
			.arg(&obj)
			.arg(asm)
			.status()
			.expect("failed to spawn clang");
		if !status.success() {
			panic!("clang failed for {}", asm);
		}

		println!("cargo:rustc-link-arg-bins={}", obj.display());
		println!("cargo:rustc-link-arg-bins=/ENTRY:_start");
	} else {
		// Other architectures not wired yet
	}
}
