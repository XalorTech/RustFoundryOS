# Canonical architecture aliases
ARCH_X64	:= x86_64
ARCH_ARM64	:= aarch64

# Supported architectures
ARCHS		:= $(ARCH_X64) $(ARCH_ARM64)

.PHONY: all x64 arm64 clean

# Default: Build `all`
all: x64 arm64

# Build x64
x64:
	@ARCH=$(ARCH_X64) $(MAKE) build

# Build arm64
arm64:
	@ARCH=$(ARCH_ARM64) $(MAKE) build

# Derived variables (expand at build time)
TARGET		= $(ARCH)-unknown-none
LD_SCRIPT	= linker/$(ARCH).ld
BOOT_ELF	= target/$(TARGET)/release/bootloader
OUT_BIN		= bootloader-$(ARCH).bin

# Generic build rule
build:
	$(if $(filter $(ARCH), $(ARCHS)), , $(error Unsupported ARCH: $(ARCH)))
	
	cargo build --release --target $(TARGET) RUSTFLAGS="-C link-arg=-T$(LD_SCRIPT)"
	llvm-objcopy -O binary $(BOOT_ELF) $(OUT_BIN)

# Clean build artifacts
clean:
	@cargo clean
	@rm -f bootloader-*.bin
