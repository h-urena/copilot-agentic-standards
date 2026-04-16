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
#   5. Copies the composed MCP config to .vscode/mcp.json (base + stack merged)
#   6. Copies .github/prompts/ (governance and audit prompt files)
#   7. Writes .github/CODEOWNERS with the detected repo owner
#   8. Copies dependabot.yml template (idempotent)
#   9. Prints branch protection setup instructions

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

# 5. MCP config (use pre-composed merged file if available, else merge on-the-fly, else copy stack file)
COMPOSED_MCP="$ROOT_DIR/composed/${STACK}.mcp.json"
MCP_FILE="$ROOT_DIR/mcp/${STACK}.mcp.json"
BASE_MCP="$ROOT_DIR/mcp/base.mcp.json"

if [ -f "$COMPOSED_MCP" ]; then
  mkdir -p "$REPO_PATH/.vscode"
  cp "$COMPOSED_MCP" "$REPO_PATH/.vscode/mcp.json"
  echo "  ✓ .vscode/mcp.json (composed)"
elif [ -f "$MCP_FILE" ]; then
  mkdir -p "$REPO_PATH/.vscode"
  if command -v jq > /dev/null 2>&1 && [ -f "$BASE_MCP" ]; then
    jq -s '.[0].servers * .[1].servers | {servers: .}' "$BASE_MCP" "$MCP_FILE" > "$REPO_PATH/.vscode/mcp.json"
    echo "  ✓ .vscode/mcp.json (merged on-the-fly)"
  else
    cp "$MCP_FILE" "$REPO_PATH/.vscode/mcp.json"
    echo "  ✓ .vscode/mcp.json (stack only — jq not found, base not merged)"
  fi
fi

# 6. Governance prompts
PROMPTS_SRC="$ROOT_DIR/.github/prompts"
if [ -d "$PROMPTS_SRC" ]; then
  mkdir -p "$REPO_PATH/.github/prompts"
  cp "$PROMPTS_SRC"/*.prompt.md "$REPO_PATH/.github/prompts/"
  echo "  ✓ .github/prompts/ (governance + audit prompts)"
fi

# 7. CODEOWNERS (detect repo owner from git remote)
REMOTE_URL="$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || true)"
REPO_OWNER=""
if [ -n "$REMOTE_URL" ]; then
  # Handle both HTTPS (github.com/owner/repo) and SSH (git@github.com:owner/repo)
  REPO_OWNER="$(echo "$REMOTE_URL" | sed -E 's|.*[:/]([^/]+)/[^/]+(.git)?$|\1|')"
fi

if [ -n "$REPO_OWNER" ]; then
  cat > "$REPO_PATH/.github/CODEOWNERS" <<EOF
# CODEOWNERS — every file requires review from the repo owner before merging.
# Enable "Require review from Code Owners" in branch protection settings.
* @${REPO_OWNER}
EOF
  echo "  ✓ .github/CODEOWNERS (@${REPO_OWNER})"
else
  echo "  ⚠ Could not detect repo owner — create .github/CODEOWNERS manually"
fi

# 8. Dependabot config (only if target repo doesn't already have one — idempotent)
DEPENDABOT_TMPL="$ROOT_DIR/templates/dependabot.yml"
if [ -f "$DEPENDABOT_TMPL" ] && [ ! -f "$REPO_PATH/.github/dependabot.yml" ]; then
  mkdir -p "$REPO_PATH/.github"
  cp "$DEPENDABOT_TMPL" "$REPO_PATH/.github/dependabot.yml"
  echo "  ✓ .github/dependabot.yml"
fi

echo ""
echo "Done! Review the changes and commit them:"
echo "  cd $REPO_PATH"
echo "  git add -A && git commit -m 'chore: onboard agentic standards ($STACK)'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "POST-ONBOARDING: Enable branch protection on the default branch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run the following commands from inside the target repo (requires admin access):"
echo ""
echo "  REPO_FULL=\"\$(git -C \"$REPO_PATH\" remote get-url origin | sed -E 's|.*[:/]([^/]+/[^/]+)(.git)?\$|\\1|')\""
echo "  DEFAULT_BRANCH=\"\$(git -C \"$REPO_PATH\" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|.*/||' || echo main)\""
echo ""
echo "  gh api repos/\${REPO_FULL}/branches/\${DEFAULT_BRANCH}/protection \\"
echo "    --method PUT \\"
echo "    -H 'Accept: application/vnd.github+json' \\"
echo "    -f 'required_status_checks[strict]=true' \\"
echo "    -f 'required_status_checks[contexts][]=Validate PR title (Conventional Commits)' \\"
echo "    -f 'required_status_checks[contexts][]=Verify squash merge is enabled' \\"
echo "    -f 'required_status_checks[contexts][]=Validate branch name' \\"
echo "    -f 'enforce_admins=false' \\"
echo "    -f 'required_pull_request_reviews[dismiss_stale_reviews]=true' \\"
echo "    -f 'required_pull_request_reviews[require_code_owner_reviews]=true' \\"
echo "    -f 'required_pull_request_reviews[required_approving_review_count]=1' \\"
echo "    -f 'restrictions=null' \\"
echo "    -f 'allow_force_pushes=false' \\"
echo "    -f 'allow_deletions=false'"
echo ""
echo "This enforces: PR-only merges, required CI checks, CODEOWNERS review, no force pushes."
