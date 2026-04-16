#!/usr/bin/env bash
# validate-composed.sh — Verifies that composed files are up to date.
# Exits non-zero if any composed file would change after re-composition.
# Used in CI to ensure nobody edited composed/ directly or forgot to regenerate.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

COMPOSED_DIR="$ROOT_DIR/composed"

# Save current composed files
TEMP_DIR=$(mktemp -d)
if [ -d "$COMPOSED_DIR" ]; then
  cp -r "$COMPOSED_DIR" "$TEMP_DIR/composed-before"
else
  mkdir -p "$TEMP_DIR/composed-before"
fi

# Regenerate all composed files
"$SCRIPT_DIR/compose.sh" all

# Compare
STALE=false

if [ -d "$TEMP_DIR/composed-before" ]; then
  for file in "$COMPOSED_DIR"/*.md "$COMPOSED_DIR"/*.json; do
    [ -f "$file" ] || continue
    fname=$(basename "$file")
    before="$TEMP_DIR/composed-before/$fname"

    if [ ! -f "$before" ]; then
      echo "NEW: composed/$fname (not previously committed)"
      STALE=true
    elif ! diff -q "$before" "$file" > /dev/null 2>&1; then
      echo "STALE: composed/$fname"
      diff --unified "$before" "$file" || true
      STALE=true
    fi
  done
fi

# Restore original composed files
rm -rf "$COMPOSED_DIR"
if [ -d "$TEMP_DIR/composed-before" ]; then
  mv "$TEMP_DIR/composed-before" "$COMPOSED_DIR"
fi
rm -rf "$TEMP_DIR"

if [ "$STALE" = true ]; then
  echo ""
  echo "ERROR: Composed files are stale. Run './scripts/compose.sh all' and commit the result."
  exit 1
else
  echo "All composed files are up to date."
fi
