# RustFoundry OS

Developer-first OS built in Rust, including console-only `Bare Metal Edition`.

## About

**RustFoundry OS** is a 64‑bit, console‑first operating system designed to run on both **x86_64** and **ARM64** architectures.
The **Bare Metal Edition** is the initial release, focused entirely on delivering a fast, minimal, and reproducible shell environment without a graphical interface.

RustFoundry OS is built with:
- **Rust** (`no_std`, `no_main`) for safety and maintainability
- **Minimal Assembly** for architecture setup and configuration during boot sequence
- **Test‑Driven Development (TDD)** from the boot sequence onward
- **Modular architecture** for portability and reproducibility

## Getting Started

### Prerequisites
- **Rust toolchain** (with `rustup`)
- **LLVM / LLD** linker
- **QEMU** for emulation
- **OVMF** UEFI firmware binaries (for x86_64; AAVMF for ARM64 later)
- **Make** (GNU Make recommended)
- **Git** (for cloning and contributing)

## Documentation

I will add a link to the documentation for RustFoundry OS here once I have it up and running.

## License

RustFoundry OS is released under the [GPLv3 License](LICENSE.md).
