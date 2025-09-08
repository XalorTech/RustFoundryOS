# ===============================================================================
# RustFoundry OS:
# Developer-first OS built in Rust, including console-only "Bare Metal Edition".
# Copyright (C) 2025 XalorTech
# License: GPLv3 (see LICENSE.md for details)
# ===============================================================================

# ----------------------------------------
# Variables & Architecture Aliases
# ----------------------------------------
# ARCH_X64 / ARCH_ARM64:
#   Canonical architecture identifiers used throughout the Makefile.
# ARCHS:
#   Space-separated list of architectures to process. Defaults to both.
# DEBUG:
#   true  -> Enable QEMU debug flags (breakpoints, logging, no reboot/shutdown).
#   false -> Normal run mode.
ARCH_X64	:= x86_64
ARCH_ARM64	:= aarch64

ARCHS		?= $(ARCH_X64) $(ARCH_ARM64)
DEBUG		?= false

# ----------------------------------------
# Default goal
# ----------------------------------------
# If no target is given, show the help text.
.DEFAULT_GOAL := help

.PHONY: help setup all clean lint build run

# ----------------------------------------
# help: Display usage, targets, and variables
# ----------------------------------------
# Prints a summary of available targets, variables, and example invocations.
# This is the first stop for new contributors.
help:
	@echo ""
	@echo "Usage: make [TARGET] [VARIABLE=value]..."
	@echo ""
	@echo "Targets:"
	@echo "  help     Show this message"
	@echo "  setup    Install all required tools and Rust components for building"
	@echo "           (runs scripts/setup_env.sh; safe to re-run anytime)"
	@echo "  all      Clean, lint, build, and run (default if no target)"
	@echo "  clean    Remove all build artifacts"
	@echo "  lint     Run static checks (license headers, real tabs, etc.)"
	@echo "  build    Build the entire RustFoundry OS for \$$ARCHS"
	@echo "           (lint is required and will stop build on failure)"
	@echo "  run      Launch QEMU for \$$ARCHS"
	@echo ""
	@echo "Variables (override with VAR=value):"
	@echo "  ARCHS    Architectures to process (default: $(ARCHS))"
	@echo "  DEBUG    true to enable QEMU debug flags (default: $(DEBUG))"
	@echo ""
	@echo "Examples:"
	@echo "  make setup                         # one-time environment setup"
	@echo "  make all ARCHS=x86_64 DEBUG=true   # clean, lint, build, and run"
	@echo "  make clean                         # remove all build artifacts"
	@echo "  make lint                          # run static checks"
	@echo "  make build ARCHS=x86_64            # build only x86_64"
	@echo "  make run ARCHS=aarch64 DEBUG=true  # run aarch64 in debug mode"
	@echo ""

# ----------------------------------------
# setup: Install all required tools and Rust components
# ----------------------------------------
# Runs the cross-platform environment setup script:
#   - Installs rustup if missing
#   - Updates Rust and adds required targets/components
#   - Installs NASM, Clang, QEMU (via apt/brew/winget)
#   - Checks minimum versions
# Safe to re-run at any time.
setup:
	@echo "[SETUP] Running environment setup script..."
	@bash scripts/setup_env.sh

# ----------------------------------------
# all: Clean → Lint → Build → Run
# ----------------------------------------
# This is the canonical build path for the entire OS — including the bootloader.
# Sequence:
#   1. clean  -> Remove all build artifacts
#   2. lint   -> Run static checks (required; stops build on failure)
#   3. build  -> Build the OS for all architectures in $(ARCHS)
#   4. run    -> Launch QEMU for each architecture
all: clean lint build run

# ----------------------------------------
# clean: Remove build artifacts
# ----------------------------------------
# Deletes all generated files and directories from previous builds.
# This ensures a clean slate for reproducible builds.
clean:
	@echo "[CLEAN] Removing all build artifacts..."
	@rm -rf target dist

# ----------------------------------------
# lint: Run all modular lint checks
# ----------------------------------------
# Runs every lint script in scripts/lint/ to enforce project coding standards:
#   - check_license_header.sh : Ensures the exact RustFoundry OS license header
#                               is present in approved file types only.
#   - check_tabs.sh           : Ensures real tabs are used for indentation
#                               (spaces only where required).
#   - check_newline_eof.sh    : Ensures a single newline at the end of each file.
#
# All lint rules are mandatory. If any check fails, the build stops immediately.
# This target is a required quality gate for all builds.
lint:
	@echo "[LINT] Running all lint checks..."
	@for script in scripts/lint/*.sh; do \
		echo "[LINT] Running $$script..."; \
		bash $$script || exit 1; \
	done
	@echo "[LINT] All checks passed — everything is awesome!"

# ----------------------------------------
# build: Build the entire RustFoundry OS for each target architecture
# ----------------------------------------
# This target:
#   1. Runs lint first (quality gate).
#   2. Invokes Cargo to build all OS components (bootloader, kernel, etc.)
#      for the specified UEFI target triple.
#   3. Produces a UEFI-compatible .EFI image for each architecture.
#   4. Copies the .EFI into dist/<arch>/EFI/BOOT with the correct UEFI boot filename
#      for use in an ESP (EFI System Partition) when running in QEMU or on hardware.
#
# Notes:
#   - The bootloader's build.rs handles assembling the architecture-specific
#     entry veneer and linking it with Rust code.
#   - This is the canonical build path for the entire OS — including the bootloader.
#   - Lint is required and will stop the build if it fails.
build: lint
	@echo "[BUILD] Building RustFoundry OS for architectures: $(ARCHS)"
	@for ARCH in $(ARCHS); do \
		echo "[BUILD] Starting full OS build for $$ARCH..."; \
		if [ "$$ARCH" = "$(ARCH_X64)" ]; then \
			TARGET_TRIPLE="x86_64-unknown-uefi"; \
			UEFI_BOOT_FILE="BOOTX64.EFI"; \
		elif [ "$$ARCH" = "$(ARCH_ARM64)" ]; then \
			TARGET_TRIPLE="aarch64-unknown-uefi"; \
			UEFI_BOOT_FILE="BOOTAA64.EFI"; \
		else \
			echo "[BUILD] Unsupported architecture: $$ARCH, skipping..."; \
			continue; \
		fi; \
		cargo build --target $$TARGET_TRIPLE --workspace; \
		OUT_DIR="target/$$TARGET_TRIPLE/debug"; \
		mkdir -p dist/$$ARCH/EFI/BOOT; \
		cp $$OUT_DIR/bootloader.efi dist/$$ARCH/EFI/BOOT/$$UEFI_BOOT_FILE; \
		echo "[BUILD] OS image ready: dist/$$ARCH/EFI/BOOT/$$UEFI_BOOT_FILE"; \
	done

# ----------------------------------------
# run: Launch QEMU for each architecture
# ----------------------------------------
# Boots the built OS in QEMU using UEFI firmware:
#   - x86_64 uses OVMF (OVMF_CODE.fd / OVMF_VARS.fd)
#   - aarch64 uses QEMU_EFI.fd (or equivalent ARM UEFI firmware)
#
# Expects:
#   - dist/<arch>/EFI/BOOT/BOOT*.EFI from the build step
#   - Firmware files present in the working directory
#
# DEBUG=true enables QEMU debug flags for breakpoints, logging, and no reboot/shutdown.
FIRMWARE_DIR := resources/firmware
OVMF_CODE := $(FIRMWARE_DIR)/OVMF_CODE.fd
OVMF_VARS := $(FIRMWARE_DIR)/OVMF_VARS.fd
QEMU_EFI := $(FIRMWARE_DIR)/QEMU_EFI.fd

run:
	@echo "[RUN] Running RustFoundry OS for architectures: $(ARCHS)"
	@for ARCH in $(ARCHS); do \
		echo "[RUN] Launching QEMU for $$ARCH..."; \
		if [ "$$ARCH" = "$(ARCH_X64)" ]; then \
			if [ ! -f $(OVMF_CODE) ] || [ ! -f $(OVMF_VARS) ]; then \
				echo "[ERROR] Missing $(OVMF_CODE) or $(OVMF_VARS)"; exit 1; \
			fi; \
			if [ ! -f dist/$$ARCH/EFI/BOOT/BOOTX64.EFI ]; then \
				echo "[ERROR] Missing dist/$$ARCH/EFI/BOOT/BOOTX64.EFI — build first"; exit 1; \
			fi; \
			ESP_DIR=dist/$$ARCH; \
			[ "$(DEBUG)" = "true" ] && DEBUG_OPTS="-s -S -d int,cpu,exec -no-reboot -no-shutdown" || DEBUG_OPTS=""; \
			qemu-system-x86_64 \
				-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
				-drive if=pflash,format=raw,file=$(OVMF_VARS) \
				-drive format=raw,file=fat:rw:$$ESP_DIR \
				$$DEBUG_OPTS; \
		elif [ "$$ARCH" = "$(ARCH_ARM64)" ]; then \
			if [ ! -f $(QEMU_EFI) ]; then \
				echo "[ERROR] Missing $(QEMU_EFI)"; exit 1; \
			fi; \
			if [ ! -f dist/$$ARCH/EFI/BOOT/BOOTAA64.EFI ]; then \
				echo "[ERROR] Missing dist/$$ARCH/EFI/BOOT/BOOTAA64.EFI — build first"; exit 1; \
			fi; \
			ESP_DIR=dist/$$ARCH; \
			[ "$(DEBUG)" = "true" ] && DEBUG_OPTS="-s -S -d int,cpu,exec -no-reboot -no-shutdown" || DEBUG_OPTS=""; \
			qemu-system-aarch64 \
				-machine virt -cpu cortex-a57 \
				-drive if=pflash,format=raw,readonly=on,file=$(QEMU_EFI) \
				-drive format=raw,file=fat:rw:$$ESP_DIR \
				$$DEBUG_OPTS; \
		else \
			echo "[RUN] Unsupported architecture: $$ARCH, skipping..."; \
		fi; \
	done
