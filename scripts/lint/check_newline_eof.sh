#!/usr/bin/env bash
set -euo pipefail

echo "[LINT] Checking for newline at EOF..."
fail_count=0

while IFS= read -r -d '' file; do
	if [ -f "$file" ]; then
		last_char=$(tail -c 1 "$file" || true)
		if [ "$last_char" != "" ]; then
			echo "[LINT][EOF] Missing newline at end of file: $file"
			((fail_count++))
		fi
	fi
done < <(git ls-files -z '*.rs' '*.asm' '*.S' '*.sh' '*.toml' '*.json' 'Makefile' '*.mk')

if [ "$fail_count" -gt 0 ]; then
	echo "[LINT] Newline at EOF check failed."
	exit 1
fi

echo "[LINT] Newline at EOF -> OK"
