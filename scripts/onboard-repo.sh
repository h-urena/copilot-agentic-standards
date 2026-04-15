#!/usr/bin/env bash
# onboard-repo.sh — Bootstraps a repository with agentic standards.
#
# Usage:
#   ./scripts/onboard-repo.sh --repo ../my-project --stack typescript
#   ./scripts/onboard-repo.sh --repo /path/to/repo --stack python
#
# What it does:
#   1. Copies the composed copilot-instructions.md to .github/
#   2. Copies code-review.instructions.md and stack-specific code-review-<stack>.instructions.md to .github/
#   3. Copies PR templates to .github/PULL_REQUEST_TEMPLATE/
#   4. Copies the pull-standards sync workflow to .github/workflows/
#   5. Copies MCP config if one exists for the stack
#   6. Prints a summary of what was set up

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 --repo <path> --stack <stack>"
  echo ""
  echo "Options:"
  echo "  --repo   Path to the target repository"
  echo "  --stack  Stack name (typescript, python, csharp)"
  echo ""
  echo "Example:"
  echo "  $0 --repo ../my-project --stack typescript"
  exit 1
}

REPO_PATH=""
STACK=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_PATH="$2"
      shift 2
      ;;
    --stack)
      STACK="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

if [ -z "$REPO_PATH" ] || [ -z "$STACK" ]; then
  usage
fi

if [ ! -d "$REPO_PATH" ]; then
  echo "Error: Repository path does not exist: $REPO_PATH"
  exit 1
fi

COMPOSED_FILE="$ROOT_DIR/composed/${STACK}-copilot-instructions.md"
if [ ! -f "$COMPOSED_FILE" ]; then
  echo "Error: Composed file not found for stack '$STACK'."
  echo "Run './scripts/compose.sh $STACK' first."
  exit 1
fi

REPO_PATH="$(cd "$REPO_PATH" && pwd)"
echo "Onboarding: $REPO_PATH (stack: $STACK)"
echo ""

# 1. Copilot instructions
mkdir -p "$REPO_PATH/.github"
cp "$COMPOSED_FILE" "$REPO_PATH/.github/copilot-instructions.md"
echo "  ✓ .github/copilot-instructions.md"

# 2. Code review instructions (generic + stack-specific)
if [ -f "$ROOT_DIR/instructions/code-review.instructions.md" ]; then
  cp "$ROOT_DIR/instructions/code-review.instructions.md" "$REPO_PATH/.github/code-review.instructions.md"
  echo "  ✓ .github/code-review.instructions.md"
fi

STACK_REVIEW="$ROOT_DIR/instructions/code-review-${STACK}.instructions.md"
if [ -f "$STACK_REVIEW" ]; then
  cp "$STACK_REVIEW" "$REPO_PATH/.github/code-review-${STACK}.instructions.md"
  echo "  ✓ .github/code-review-${STACK}.instructions.md"
fi

# 3. PR templates
mkdir -p "$REPO_PATH/.github/PULL_REQUEST_TEMPLATE"
for tmpl in "$ROOT_DIR"/templates/pull-request/*.md; do
  [ -f "$tmpl" ] || continue
  cp "$tmpl" "$REPO_PATH/.github/PULL_REQUEST_TEMPLATE/"
  echo "  ✓ .github/PULL_REQUEST_TEMPLATE/$(basename "$tmpl")"
done

# 4. Sync workflow
mkdir -p "$REPO_PATH/.github/workflows"
cp "$ROOT_DIR/workflows/sync/pull-standards.yml" "$REPO_PATH/.github/workflows/pull-standards.yml"
echo "  ✓ .github/workflows/pull-standards.yml"

# 5. MCP config
MCP_FILE="$ROOT_DIR/mcp/${STACK}.mcp.json"
if [ -f "$MCP_FILE" ]; then
  # Merge with base MCP config
  if command -v jq > /dev/null 2>&1 && [ -f "$ROOT_DIR/mcp/base.mcp.json" ]; then
    jq -s '.[0] * .[1]' "$ROOT_DIR/mcp/base.mcp.json" "$MCP_FILE" > "$REPO_PATH/.vscode/mcp.json"
  else
    cp "$MCP_FILE" "$REPO_PATH/.vscode/mcp.json"
  fi
  echo "  ✓ .vscode/mcp.json"
fi

echo ""
echo "Done! Review the changes and commit them:"
echo "  cd $REPO_PATH"
echo "  git add -A && git commit -m 'chore: onboard agentic standards ($STACK)'"
