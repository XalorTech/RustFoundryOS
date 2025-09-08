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
	let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR not set"));

	// Define veneer source paths once
	let x86_64_src = manifest_dir.join("asm/x86_64/entry.asm");
	let aarch64_src = manifest_dir.join("asm/aarch64/entry.S");

	// Always rebuild if veneers change
	println!("cargo:rerun-if-changed={}", x86_64_src.display());
	println!("cargo:rerun-if-changed={}", aarch64_src.display());

	if target.starts_with("x86_64") {
		let obj = out_dir.join("entry_x86_64.obj");

		let status = Command::new("nasm")
			.args(["-f", "win64", "-g", "-o"])
			.arg(&obj)
			.arg(&x86_64_src)
			.status()
			.expect("failed to spawn nasm");
		if !status.success() {
			panic!("nasm failed for {}", x86_64_src.display());
		}

		println!("cargo:rustc-link-arg-bins={}", obj.display());
		println!("cargo:rustc-link-arg-bins=/ENTRY:_start");

	} else if target.starts_with("aarch64") {
		let obj = out_dir.join("entry_aarch64.obj");

		let status = Command::new("clang")
			.args([
				"-c",
				"-target", "aarch64-windows",
				"-g",
				"-o",
			])
			.arg(&obj)
			.arg(&aarch64_src)
			.status()
			.expect("failed to spawn clang");
		if !status.success() {
			panic!("clang failed for {}", aarch64_src.display());
		}

		println!("cargo:rustc-link-arg-bins={}", obj.display());
		println!("cargo:rustc-link-arg-bins=/ENTRY:_start");

	} else {
		// Other architectures not wired yet
	}
}
