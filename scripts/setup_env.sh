#!/usr/bin/env bash
set -euo pipefail

# -------- Minimum versions --------
MIN_RUST="1.80.0"
MIN_NASM="2.15"
MIN_CLANG="10.0.0"
MIN_QEMU="6.0.0"

# -------- Helper: compare versions --------
ver_ge() { [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# -------- Detect OS --------
OS="$(uname -s)"
case "$OS" in
	Linux*)					PLATFORM="linux" ;;
	Darwin*)				PLATFORM="macos" ;;
	MINGW*|MSYS*|CYGWIN*)	PLATFORM="windows" ;;
	*) echo "[ERROR] Unsupported OS: $OS"; exit 1 ;;
esac

echo "[SETUP] Detected platform: $PLATFORM"

# -------- Prompt for sudo privileges --------
if [ "$EUID" -ne 0 ]; then
	echo "[SETUP] Some steps require sudo privileges. You may be prompted for your password."
	sudo -v
fi

# -------- Install rustup if missing --------
if ! command -v rustup >/dev/null 2>&1; then
	echo "[SETUP] Installing rustup..."
	if [ "$PLATFORM" = "windows" ]; then
		echo "[ERROR] Please install rustup from https://win.rustup.rs/ and re-run this script."
		exit 1
	else
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
		source "$HOME/.cargo/env"
	fi
fi

# -------- Update Rust and check version --------
rustup update
RUST_VER=$(rustc --version | awk '{print $2}')
if ! ver_ge "$RUST_VER" "$MIN_RUST"; then
	echo "[ERROR] Rust $MIN_RUST or newer required (found $RUST_VER)"
	exit 1
fi
echo "[OK] Rust version $RUST_VER"

# -------- Install required Rust targets --------
rustup target add x86_64-unknown-uefi
rustup target add aarch64-unknown-uefi

# -------- Install required Rust components --------
rustup component add rust-src llvm-tools-preview clippy rustfmt

# -------- Install NASM --------
if ! command -v nasm >/dev/null 2>&1; then
	echo "[SETUP] Installing NASM..."
	case "$PLATFORM" in
		linux)		sudo apt-get update && sudo apt-get install -y nasm ;;
		macos)		brew install nasm ;;
		windows)	winget install --id=NASM.NASM -e --source winget ;;
	esac
fi
NASM_VER=$(nasm -v | awk '{print $3}')
if ! ver_ge "$NASM_VER" "$MIN_NASM"; then
	echo "[ERROR] NASM $MIN_NASM or newer required (found $NASM_VER)"
	exit 1
fi
echo "[OK] NASM version $NASM_VER"

# -------- Install Clang --------
if ! command -v clang >/dev/null 2>&1; then
	echo "[SETUP] Installing Clang..."
	case "$PLATFORM" in
		linux)		sudo apt-get install -y clang ;;
		macos)		brew install llvm ;;
		windows)	winget install --id=LLVM.LLVM -e --source winget ;;
	esac
fi
CLANG_VER=$(clang --version | head -n1 | awk '{print $3}')
if ! ver_ge "$CLANG_VER" "$MIN_CLANG"; then
	echo "[ERROR] Clang $MIN_CLANG or newer required (found $CLANG_VER)"
	exit 1
fi
echo "[OK] Clang version $CLANG_VER"

# -------- Install QEMU --------
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
	echo "[SETUP] Installing QEMU..."
	case "$PLATFORM" in
		linux)		sudo apt-get install -y qemu-system-x86 qemu-system-arm ;;
		macos)		brew install qemu ;;
		windows)	winget install --id=QEMU.QEMU -e --source winget ;;
	esac
fi
QEMU_VER=$(qemu-system-x86_64 --version | head -n1 | awk '{print $4}')
if ! ver_ge "$QEMU_VER" "$MIN_QEMU"; then
	echo "[ERROR] QEMU $MIN_QEMU or newer required (found $QEMU_VER)"
	exit 1
fi
echo "[OK] QEMU version $QEMU_VER"

# -------- Install UEFI firmware for QEMU --------
echo "[SETUP] Installing UEFI firmware for QEMU..."
FIRMWARE_DIR="resources/firmware"
mkdir -p "$FIRMWARE_DIR"

case "$PLATFORM" in
	linux)
		if command -v apt-get >/dev/null 2>&1; then
			sudo apt-get install -y ovmf qemu-efi-aarch64
			OVMF_SRC_DIR="/usr/share/OVMF"
			CODE_LEGACY="$OVMF_SRC_DIR/OVMF_CODE.fd"
			VARS_LEGACY="$OVMF_SRC_DIR/OVMF_VARS.fd"
			CODE_4M="$OVMF_SRC_DIR/OVMF_CODE_4M.fd"
			VARS_4M="$OVMF_SRC_DIR/OVMF_VARS_4M.fd"
			if [ -f "$CODE_LEGACY" ] && [ -f "$VARS_LEGACY" ]; then
				sudo cp "$CODE_LEGACY" "$FIRMWARE_DIR/OVMF_CODE.fd"
				sudo cp "$VARS_LEGACY" "$FIRMWARE_DIR/OVMF_VARS.fd"
				sudo chmod 644 "$FIRMWARE_DIR/OVMF_CODE.fd" "$FIRMWARE_DIR/OVMF_VARS.fd"
				sudo chown $USER:$USER "$FIRMWARE_DIR/OVMF_CODE.fd" "$FIRMWARE_DIR/OVMF_VARS.fd"
				echo "[SETUP] Copied legacy OVMF firmware files for QEMU."
			elif [ -f "$CODE_4M" ] && [ -f "$VARS_4M" ]; then
				sudo cp "$CODE_4M" "$FIRMWARE_DIR/OVMF_CODE.fd"
				sudo cp "$VARS_4M" "$FIRMWARE_DIR/OVMF_VARS.fd"
				sudo chmod 644 "$FIRMWARE_DIR/OVMF_CODE.fd" "$FIRMWARE_DIR/OVMF_VARS.fd"
				sudo chown $USER:$USER "$FIRMWARE_DIR/OVMF_CODE.fd" "$FIRMWARE_DIR/OVMF_VARS.fd"
				echo "[SETUP] Copied OVMF 4M firmware files for QEMU."
			else
				echo "[SETUP] OVMF firmware files not found. Please install the 'ovmf' package."
			fi
			sudo cp /usr/share/AAVMF/AAVMF_CODE.fd "$FIRMWARE_DIR/QEMU_EFI.fd" 2>/dev/null || true
		elif command -v dnf >/dev/null 2>&1; then
			sudo dnf install -y edk2-ovmf edk2-aarch64
			ln -sf /usr/share/edk2/ovmf/OVMF_CODE.fd "$FIRMWARE_DIR/OVMF_CODE.fd" 2>/dev/null || true
			ln -sf /usr/share/edk2/ovmf/OVMF_VARS.fd "$FIRMWARE_DIR/OVMF_VARS.fd" 2>/dev/null || true
			ln -sf /usr/share/edk2/aarch64/QEMU_EFI.fd "$FIRMWARE_DIR/QEMU_EFI.fd" 2>/dev/null || true
		fi
		;;
	macos)
		brew install qemu
		cp "$(brew --prefix qemu)/share/qemu/edk2-x86_64-code.fd" "$FIRMWARE_DIR/OVMF_CODE.fd" 2>/dev/null || true
		cp "$(brew --prefix qemu)/share/qemu/edk2-x86_64-vars.fd" "$FIRMWARE_DIR/OVMF_VARS.fd" 2>/dev/null || true
		cp "$(brew --prefix qemu)/share/qemu/edk2-aarch64-code.fd" "$FIRMWARE_DIR/QEMU_EFI.fd" 2>/dev/null || true
		chmod 644 "$FIRMWARE_DIR/OVMF_CODE.fd" "$FIRMWARE_DIR/OVMF_VARS.fd" "$FIRMWARE_DIR/QEMU_EFI.fd" 2>/dev/null || true
		;;
	windows)
		winget install --id=QEMU.QEMU -e --source winget
		echo "[INFO] Please copy OVMF_CODE.fd / OVMF_VARS.fd / QEMU_EFI.fd into $FIRMWARE_DIR"
		;;
esac

echo "[OK] Firmware files copied to $FIRMWARE_DIR"
