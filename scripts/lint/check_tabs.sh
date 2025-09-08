#!/usr/bin/env bash
set -euo pipefail

echo "[LINT] Checking for tab indentation..."
fail_count=0

while IFS= read -r -d '' file; do
	if file "$file" | grep -q "text"; then
		if grep -P '^( {2,})\S' "$file" >/dev/null; then
			echo "[LINT][TABS] Leading spaces found instead of tabs: $file"
			((fail_count++))
		fi
	fi
done < <(git ls-files -z '*.rs' '*.asm' '*.S' '*.sh' '*.toml' '*.json' 'Makefile' '*.mk')

if [ "$fail_count" -gt 0 ]; then
	echo "[LINT] Tab indentation check failed."
	exit 1
fi

echo "[LINT] Tab indentation -> OK"
