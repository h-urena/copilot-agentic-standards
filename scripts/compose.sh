#!/usr/bin/env bash
# compose.sh — Merges instructions/base.md + instructions/stacks/<stack>.md
# into composed/<stack>-copilot-instructions.md
#
# Usage:
#   ./scripts/compose.sh typescript
#   ./scripts/compose.sh all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTRUCTIONS_DIR="$ROOT_DIR/instructions"
STACKS_DIR="$INSTRUCTIONS_DIR/stacks"
COMPOSED_DIR="$ROOT_DIR/composed"
MCP_DIR="$ROOT_DIR/mcp"

AVAILABLE_STACKS=()
for f in "$STACKS_DIR"/*.md; do
  [ -f "$f" ] || continue
  AVAILABLE_STACKS+=("$(basename "$f" .md)")
done

compose_stack() {
  local stack="$1"
  local stack_file="$STACKS_DIR/${stack}.md"
  local output_file="$COMPOSED_DIR/${stack}-copilot-instructions.md"

  if [ ! -f "$stack_file" ]; then
    echo "Error: Stack file not found: $stack_file" >&2
    return 1
  fi

  mkdir -p "$COMPOSED_DIR"

  cat > "$output_file" <<EOF
<!-- AUTO-GENERATED — do not edit. Regenerate with: ./scripts/compose.sh ${stack} -->
<!-- Source: instructions/base.md + instructions/stacks/${stack}.md -->
<!-- Stack: ${stack} -->

EOF

  {
    cat "$INSTRUCTIONS_DIR/base.md"
    echo ""
    echo "---"
    echo ""
    cat "$stack_file"
  } >> "$output_file"

  echo "  ✓ composed/${stack}-copilot-instructions.md"
}

compose_mcp() {
  local stack="$1"
  local stack_mcp="$MCP_DIR/${stack}.mcp.json"
  local base_mcp="$MCP_DIR/base.mcp.json"
  local output_file="$COMPOSED_DIR/${stack}.mcp.json"

  # Only compose if a stack-specific MCP file exists
  if [ ! -f "$stack_mcp" ]; then
    return 0
  fi

  if ! command -v jq > /dev/null 2>&1; then
    echo "  ⚠ jq not found — skipping MCP composition for ${stack}" >&2
    return 0
  fi

  mkdir -p "$COMPOSED_DIR"
  # Deep-merge base servers + stack servers (stack wins on conflict)
  jq -s '.[0].servers * .[1].servers | {servers: .}' "$base_mcp" "$stack_mcp" > "$output_file"
  echo "  ✓ composed/${stack}.mcp.json"
}

if [ $# -eq 0 ]; then
  echo "Usage: $0 <stack|all>"
  echo ""
  echo "Available stacks: ${AVAILABLE_STACKS[*]}"
  exit 1
fi

TARGET="$1"

if [ "$TARGET" = "all" ]; then
  echo "Composing all stacks..."
  for stack in "${AVAILABLE_STACKS[@]}"; do
    compose_stack "$stack"
    compose_mcp "$stack"
  done
  echo "Done."
else
  compose_stack "$TARGET"
  compose_mcp "$TARGET"
fi