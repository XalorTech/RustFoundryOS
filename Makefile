# ----------------------------------------
# Variables & Architecture Aliases
# ----------------------------------------
ARCH_X64   := x86_64
ARCH_ARM64 := aarch64

ARCHS ?= $(ARCH_X64) $(ARCH_ARM64)
DEBUG ?= false

# ----------------------------------------
# Default goal: if no target is given, show help
# ----------------------------------------
.DEFAULT_GOAL := help

.PHONY: help all clean build run

# ----------------------------------------
# help: display usage, targets, variables
# ----------------------------------------
help:
	@echo ""
	@echo "Usage: make [TARGET] [VARIABLE=value]..."
	@echo ""
	@echo "Targets:"
	@echo "  help     Show this message"
	@echo "  all      Clean, build, and run (default if no target)"
	@echo "  clean    Remove all build artifacts"
	@echo "  build    Assemble bootsectors for \$$ARCHS"
	@echo "  run      Launch QEMU for \$$ARCHS"
	@echo ""
	@echo "Variables (override with VAR=value):"
	@echo "  ARCHS    Architectures to process (default: $(ARCHS))"
	@echo "  DEBUG    true to enable QEMU debug flags (default: $(DEBUG))"
	@echo ""
	@echo "Examples:"
	@echo "  make build ARCHS=x86_64            # build only x86_64"
	@echo "  make run ARCHS=aarch64 DEBUG=true  # run aarch64 in debug mode"
	@echo ""

# ----------------------------------------
# all: clean → build → run
# ----------------------------------------
all: clean build run

# ----------------------------------------
# clean: remove artifacts
# ----------------------------------------
clean:
	@echo "[CLEAN] Removing all build artifacts..."
	@rm -rf target

# ----------------------------------------
# build: assemble per‐ARCH
# ----------------------------------------
build:
	@echo "[BUILD] Building for architectures: $(ARCHS)"
	@for ARCH in $(ARCHS); do \
	  echo "[BUILD] Building for $$ARCH..."; \
	  TARGET=$$ARCH-unknown-none; \
	  ASM_SRC_DIR=bootloader/asm/$$ARCH; \
	  ASM_BIN_DIR=target/$$TARGET/artifacts; \
	  ASM_SRC=$$ASM_SRC_DIR/bootsector.asm; \
	  ASM_BIN=$$ASM_BIN_DIR/bootsector.bin; \
	  mkdir -p $$ASM_BIN_DIR; \
	  if [ -f $$ASM_SRC ]; then \
	    echo "[BUILD] Assembling $$ASM_SRC"; \
	    nasm -f bin -I $$ASM_SRC_DIR -o $$ASM_BIN $$ASM_SRC; \
	  else \
	    echo "[BUILD] No source for $$ARCH, skipping..."; \
	  fi; \
	done

# ----------------------------------------
# run: qemu per‐ARCH
# ----------------------------------------
run:
	@echo "[RUN] Running for architectures: $(ARCHS)"
	@for ARCH in $(ARCHS); do \
	  echo "[RUN] Launching QEMU for $$ARCH..."; \
	  TARGET=$$ARCH-unknown-none; \
	  ASM_BIN_DIR=target/$$TARGET/artifacts; \
	  IMG=$$ASM_BIN_DIR/bootsector.bin; \
	  DRIVE=format=raw,file=$$IMG; \
	  DEBUG_OPTS=""; \
	  if [ "$(DEBUG)" = "true" ]; then \
	    DEBUG_OPTS="-s -S -d int,cpu,exec -no-reboot -no-shutdown \
	                -D $$ASM_BIN_DIR/qemu.log"; \
	  fi; \
	  if [ "$$ARCH" = "x86_64" ]; then \
	    QEMU_OPTS="-drive $$DRIVE $$DEBUG_OPTS"; \
	  elif [ "$$ARCH" = "aarch64" ]; then \
	    QEMU_OPTS="-machine virt -cpu cortex-a57 -nographic \
	                -drive $$DRIVE $$DEBUG_OPTS"; \
	  else \
	    echo "[RUN] No run command for $$ARCH, skipping..."; \
	    continue; \
	  fi; \
	  qemu-system-$$ARCH $$QEMU_OPTS; \
	done
