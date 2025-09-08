#!/usr/bin/env bash
set -euo pipefail

echo "[LINT] Checking license headers..."
fail_count=0

# Directories to ignore (regex for grep -Ev)
IGNORE_DIRS='^(\.cargo/|dist/|target/)'

while IFS= read -r -d '' file; do
	# Skip ignored directories
	if echo "$file" | grep -Eq "$IGNORE_DIRS"; then
		continue
	fi

	# Determine the appropriate header file based on the file extension
	case "$file" in
		*.rs|*.S)							header_file="scripts/lint/license_headers/header_slash.txt" ;;
		*.asm)								header_file="scripts/lint/license_headers/header_semicolon.txt" ;;
		*.toml|*.json|Makefile|*.mk)		header_file="scripts/lint/license_headers/header_hash.txt" ;;
		*) continue ;;
	esac

	# Compare the beginning of the file with the expected header
	header_lines=$(wc -l < "$header_file")
	if ! head -n "$header_lines" "$file" | diff -q "$header_file" - >/dev/null; then
		echo "[LINT][HEADER] License header mismatch: $file"
		((fail_count++))
	fi
done < <(git ls-files -z)

if [ "$fail_count" -gt 0 ]; then
	echo "[LINT] License header check failed."
	exit 1
fi

echo "[LINT] License headers -> OK"
