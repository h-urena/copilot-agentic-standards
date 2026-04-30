#!/usr/bin/env bash
# onboard-repo.sh — Bootstraps a repository with agentic standards.
#
# Usage:
#   ./scripts/onboard-repo.sh --repo ../my-project --stack typescript
#   ./scripts/onboard-repo.sh --repo /path/to/repo --stack python
#   ./scripts/onboard-repo.sh --repo /path/to/repo --stack typescript+python  (multi-stack)
#   ./scripts/onboard-repo.sh --repo ../new-service --stack python --create
#   ./scripts/onboard-repo.sh --repo ../existing   --stack python --force
#
# Options:
#   --create        Create the GitHub repo (via gh CLI) and clone it before onboarding
#   --force         Overwrite files that are normally skipped when they already exist
#   --visibility    public|private — used with --create (default: private)
#   --project-name  Name for the GitHub Project board (default: "<repo-name> Roadmap")
#
# Environment variables:
#   GH_PROJECT_PAT  Classic PAT with 'project' scope — enables automatic project board creation.
#                   Fine-grained PATs do NOT support the Projects v2 API.
#
# What it does:
#   1. Copies the composed copilot-instructions.md to .github/
#   2. Copies code-review.instructions.md and stack-specific code-review-<stack>.instructions.md to .github/
#   3. Copies domain instruction files (*.instructions.md, excluding code-review) to .github/
#   4. Copies PR templates to .github/PULL_REQUEST_TEMPLATE/
#   5. Copies all distributable workflows from .github/workflows/ (excludes validate.yml)
#   6. Copies the composed MCP config to .vscode/mcp.json (base + stack merged)
#   7. Copies all .github/prompts/ subdirectories (implementation, review, scaffolds, personas, ...)
#   8. Writes .github/CODEOWNERS with the detected repo owner
#   9. Copies stack-specific dependabot.yml template (idempotent)
#  10. Copies .vscode/extensions.json with stack-specific extension recommendations
#  11. Copies templates/memory/project-context.md to .github/project-context.md
#  12. Copies .editorconfig to repo root
#  13. Copies labeler.yml to .github/labeler.yml
#  14. Copies Docker templates (Dockerfile, .dockerignore, docker-compose.yml)
#  15. Copies stack-specific CI pipeline + release.yml + stale.yml templates
#  16. Copies Copilot Skill files to .github/skills/
#  17. Creates conventional commit labels (feat, fix, chore, docs, refactor, perf, test, ci, style)
#  18. Creates GitHub Project board with columns: Todo → In Progress → In Review → Done
#       (requires GH_PROJECT_PAT env var — classic PAT with 'project' scope)
#  19. Prints post-onboarding instructions (branch protection + board setup if step 18 skipped)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  echo "Usage: $0 --repo <path> --stack <stack> [--create] [--force] \
[--visibility public|private] [--project-name <name>]"
  echo ""
  echo "Options:"
  echo "  --repo          Path to the target repository (must exist, unless --create is used)"
  echo "  --stack         Stack name: typescript, python, csharp, or multi e.g. typescript+python"
  echo "  --create        Create the GitHub repo via gh CLI and clone it before onboarding"
  echo "  --force         Overwrite files that are normally skipped when they already exist"
  echo "  --visibility    Repository visibility when using --create (default: private)"
  echo "  --project-name  Name for the GitHub Project board (default: \"<repo-name> Roadmap\")"
  echo ""
  echo "Environment variables:"
  echo "  GH_PROJECT_PAT  Classic PAT with 'project' scope for automatic board creation."
  echo "                  Fine-grained PATs do NOT support the Projects v2 API."
  echo ""
  echo "Examples:"
  echo "  $0 --repo ../my-project --stack typescript"
  echo "  $0 --repo ../new-service --stack python --create"
  echo "  $0 --repo ../new-service --stack python --create --visibility public"
  echo "  $0 --repo ../existing-project --stack python --force"
  exit 1
}

REPO_PATH=""
STACK=""
CREATE=false
FORCE=false
VISIBILITY=private
PROJECT_NAME=""

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
    --create)
      CREATE=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --visibility)
      VISIBILITY="$2"
      if [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]]; then
        echo "Error: --visibility must be 'public' or 'private'"
        exit 1
      fi
      shift 2
      ;;
    --project-name)
      PROJECT_NAME="$2"
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

# --create: provision the GitHub repo and clone it before onboarding
if [ "$CREATE" = true ]; then
  if [ -d "$REPO_PATH" ]; then
    echo "Error: --create specified but '$REPO_PATH' already exists."
    echo "       Use --force to re-onboard an existing repo (without --create)."
    exit 1
  fi
  if ! command -v gh > /dev/null 2>&1; then
    echo "Error: 'gh' CLI is required for --create. Install from https://cli.github.com"
    exit 1
  fi
  GH_USER="$(gh api user --jq .login)"
  REPO_NAME="$(basename "$REPO_PATH")"
  echo "Creating GitHub repository: ${GH_USER}/${REPO_NAME} (${VISIBILITY})..."
  if [ "$VISIBILITY" = "private" ]; then
    gh repo create "${GH_USER}/${REPO_NAME}" --private
  else
    gh repo create "${GH_USER}/${REPO_NAME}" --public
  fi
  git clone "https://github.com/${GH_USER}/${REPO_NAME}.git" "$REPO_PATH"
  echo "  ✓ Repository created and cloned to $REPO_PATH"
  echo ""
fi

if [ ! -d "$REPO_PATH" ]; then
  echo "Error: Repository path does not exist: $REPO_PATH"
  exit 1
fi

COMPOSED_FILE="$ROOT_DIR/composed/${STACK}-copilot-instructions.md"
# For multi-stack, the composed filename uses sorted stacks joined by '+'
if [[ "$STACK" == *"+"* ]]; then
  IFS='+' read -ra STACK_PARTS <<< "$STACK"
  SORTED_STACK="$(printf '%s\n' "${STACK_PARTS[@]}" | sort | paste -sd '+' -)"
  COMPOSED_FILE="$ROOT_DIR/composed/${SORTED_STACK}-copilot-instructions.md"
  PRIMARY_STACK="${STACK_PARTS[0]}"
else
  SORTED_STACK="$STACK"
  STACK_PARTS=("$STACK")
  PRIMARY_STACK="$STACK"
fi

if [ ! -f "$COMPOSED_FILE" ]; then
  echo "Error: Composed file not found for stack '$STACK'."
  echo "Run './scripts/compose.sh $STACK' first."
  exit 1
fi

REPO_PATH="$(cd "$REPO_PATH" && pwd)"
echo "Onboarding: $REPO_PATH (stack: $STACK)"
echo ""

# Returns 0 (true) if the destination file should be written.
# Normal mode: skip files that already exist (idempotent re-runs).
# --force mode: always write, pulling in the latest version.
should_write() {
  [ "$FORCE" = true ] || [ ! -f "$1" ]
}

# Calls gh CLI using GH_PROJECT_PAT (classic PAT with 'project' scope) when available,
# falling back to the default gh auth. Scoped to a subshell so it doesn't pollute env.
_gh_project() {
  if [ -n "${GH_PROJECT_PAT:-}" ]; then
    GH_TOKEN="$GH_PROJECT_PAT" gh "$@"
  else
    gh "$@"
  fi
}

# 1. Copilot instructions
mkdir -p "$REPO_PATH/.github"
cp "$COMPOSED_FILE" "$REPO_PATH/.github/copilot-instructions.md"
echo "  ✓ .github/copilot-instructions.md"

# 2. Code review instructions (generic + stack-specific)
if [ -f "$ROOT_DIR/instructions/code-review.instructions.md" ]; then
  cp "$ROOT_DIR/instructions/code-review.instructions.md" "$REPO_PATH/.github/code-review.instructions.md"
  echo "  ✓ .github/code-review.instructions.md"
fi

for s in "${STACK_PARTS[@]}"; do
  STACK_REVIEW="$ROOT_DIR/instructions/code-review-${s}.instructions.md"
  if [ -f "$STACK_REVIEW" ]; then
    cp "$STACK_REVIEW" "$REPO_PATH/.github/code-review-${s}.instructions.md"
    echo "  ✓ .github/code-review-${s}.instructions.md"
  fi
done

# 3. Domain instruction files (glob-discovered; code-review files handled separately above)
for src in "$ROOT_DIR/instructions/"*.instructions.md; do
  [ -f "$src" ] || continue
  fname="$(basename "$src")"
  case "$fname" in
    code-review*) continue ;;
  esac
  cp "$src" "$REPO_PATH/.github/$fname"
  echo "  ✓ .github/$fname"
done

# 4. PR templates
mkdir -p "$REPO_PATH/.github/PULL_REQUEST_TEMPLATE"
for tmpl in "$ROOT_DIR"/templates/pull-request/*.md; do
  [ -f "$tmpl" ] || continue
  cp "$tmpl" "$REPO_PATH/.github/PULL_REQUEST_TEMPLATE/"
  echo "  ✓ .github/PULL_REQUEST_TEMPLATE/$(basename "$tmpl")"
done

# 5. Sync workflow + all distributable agentic workflows
#    validate.yml is excluded — it is internal to the standards repo only.
mkdir -p "$REPO_PATH/.github/workflows"
cp "$ROOT_DIR/workflows/sync/pull-standards.yml" "$REPO_PATH/.github/workflows/pull-standards.yml"
echo "  ✓ .github/workflows/pull-standards.yml"

for WF_SRC in "$ROOT_DIR/.github/workflows/"*.yml; do
  [ -f "$WF_SRC" ] || continue
  wf="$(basename "$WF_SRC")"
  case "$wf" in
    validate.yml) continue ;;  # internal to copilot-agentic-standards only
  esac
  cp "$WF_SRC" "$REPO_PATH/.github/workflows/$wf"
  echo "  ✓ .github/workflows/$wf"
done

# 6. MCP config (use pre-composed merged file if available, else merge on-the-fly, else copy stack file)
COMPOSED_MCP="$ROOT_DIR/composed/${SORTED_STACK}.mcp.json"
MCP_FILE="$ROOT_DIR/mcp/${PRIMARY_STACK}.mcp.json"
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

# 7. Prompt files — loop over all subdirectories so new categories are picked up automatically.
PROMPTS_SRC="$ROOT_DIR/.github/prompts"
if [ -d "$PROMPTS_SRC" ]; then
  for prompt_dir in "$PROMPTS_SRC"/*/; do
    [ -d "$prompt_dir" ] || continue
    subdir="$(basename "$prompt_dir")"
    mkdir -p "$REPO_PATH/.github/prompts/$subdir"
    cp "$prompt_dir"*.prompt.md "$REPO_PATH/.github/prompts/$subdir/" 2>/dev/null || true
    echo "  ✓ .github/prompts/$subdir/"
  done
fi

# 8. CODEOWNERS (detect repo owner from git remote)
REMOTE_URL="$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || true)"
REPO_OWNER=""
if [ -n "$REMOTE_URL" ]; then
  # Handle both HTTPS (github.com/owner/repo) and SSH (user:host/owner/repo) remote URL formats
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

# 9. Dependabot config — use stack-specific template if available, fall back to base (idempotent)
DEPENDABOT_STACK_TMPL="$ROOT_DIR/templates/dependabot.${PRIMARY_STACK}.yml"
DEPENDABOT_BASE_TMPL="$ROOT_DIR/templates/dependabot.yml"
if should_write "$REPO_PATH/.github/dependabot.yml"; then
  mkdir -p "$REPO_PATH/.github"
  if [ -f "$DEPENDABOT_STACK_TMPL" ]; then
    cp "$DEPENDABOT_STACK_TMPL" "$REPO_PATH/.github/dependabot.yml"
    echo "  ✓ .github/dependabot.yml (${PRIMARY_STACK} template — github-actions + ${PRIMARY_STACK} ecosystem)"
  elif [ -f "$DEPENDABOT_BASE_TMPL" ]; then
    cp "$DEPENDABOT_BASE_TMPL" "$REPO_PATH/.github/dependabot.yml"
    echo "  ✓ .github/dependabot.yml (base template — uncomment stack ecosystem manually)"
  fi
fi

# 10. VS Code extension recommendations
EXT_TMPL="$ROOT_DIR/templates/vscode/extensions.${PRIMARY_STACK}.json"
if [ -f "$EXT_TMPL" ]; then
  mkdir -p "$REPO_PATH/.vscode"
  if should_write "$REPO_PATH/.vscode/extensions.json"; then
    cp "$EXT_TMPL" "$REPO_PATH/.vscode/extensions.json"
    echo "  ✓ .vscode/extensions.json (${PRIMARY_STACK} recommendations)"
  fi
fi

# 11. Project memory bootstrap template
MEMORY_TMPL="$ROOT_DIR/templates/memory/project-context.md"
if [ -f "$MEMORY_TMPL" ] && should_write "$REPO_PATH/.github/project-context.md"; then
  cp "$MEMORY_TMPL" "$REPO_PATH/.github/project-context.md"
  echo "  ✓ .github/project-context.md (memory bootstrap — fill in project details)"
fi

# 12. EditorConfig
EDITORCONFIG_TMPL="$ROOT_DIR/templates/.editorconfig"
if [ -f "$EDITORCONFIG_TMPL" ] && should_write "$REPO_PATH/.editorconfig"; then
  cp "$EDITORCONFIG_TMPL" "$REPO_PATH/.editorconfig"
  echo "  ✓ .editorconfig"
fi

# 13. Labeler config (used by pr-automation workflow)
LABELER_TMPL="$ROOT_DIR/templates/labeler.yml"
if [ -f "$LABELER_TMPL" ] && should_write "$REPO_PATH/.github/labeler.yml"; then
  cp "$LABELER_TMPL" "$REPO_PATH/.github/labeler.yml"
  echo "  ✓ .github/labeler.yml"
fi

# 14. Docker templates (Dockerfile, .dockerignore, docker-compose.yml)
DOCKER_TMPL_DIR="$ROOT_DIR/templates/docker"
DOCKERFILE_TMPL="$DOCKER_TMPL_DIR/Dockerfile.${PRIMARY_STACK}"
if [ -f "$DOCKERFILE_TMPL" ] && should_write "$REPO_PATH/Dockerfile"; then
  cp "$DOCKERFILE_TMPL" "$REPO_PATH/Dockerfile"
  echo "  ✓ Dockerfile (${PRIMARY_STACK} template)"
fi
if [ -f "$DOCKER_TMPL_DIR/.dockerignore" ] && should_write "$REPO_PATH/.dockerignore"; then
  cp "$DOCKER_TMPL_DIR/.dockerignore" "$REPO_PATH/.dockerignore"
  echo "  ✓ .dockerignore"
fi
if [ -f "$DOCKER_TMPL_DIR/docker-compose.yml" ] && should_write "$REPO_PATH/docker-compose.yml"; then
  cp "$DOCKER_TMPL_DIR/docker-compose.yml" "$REPO_PATH/docker-compose.yml"
  echo "  ✓ docker-compose.yml (development template)"
fi

# 15. CI pipeline template (stack-specific) + general CI support templates
CI_TMPL="$ROOT_DIR/templates/ci/ci.${PRIMARY_STACK}.yml"
if [ -f "$CI_TMPL" ] && should_write "$REPO_PATH/.github/workflows/ci.yml"; then
  mkdir -p "$REPO_PATH/.github/workflows"
  cp "$CI_TMPL" "$REPO_PATH/.github/workflows/ci.yml"
  echo "  ✓ .github/workflows/ci.yml (${PRIMARY_STACK} pipeline)"
fi
# release.yml and stale.yml are stack-agnostic; deploy once (idempotent — users may customise them).
for _ci_tmpl in release.yml stale.yml; do
  if [ -f "$ROOT_DIR/templates/ci/$_ci_tmpl" ] && should_write "$REPO_PATH/.github/workflows/$_ci_tmpl"; then
    cp "$ROOT_DIR/templates/ci/$_ci_tmpl" "$REPO_PATH/.github/workflows/$_ci_tmpl"
    echo "  ✓ .github/workflows/$_ci_tmpl"
  fi
done

# 16. Copilot Skill files
SKILLS_SRC="$ROOT_DIR/skills"
if [ -d "$SKILLS_SRC" ]; then
  mkdir -p "$REPO_PATH/.github/skills"
  cp "$SKILLS_SRC"/*.skill.md "$REPO_PATH/.github/skills/"
  echo "  ✓ .github/skills/ (Copilot Skill files)"
fi

# Detect full repo slug (owner/repo) once — reused by steps 17 and 18.
_REPO_FULL=""
_REPO_OWNER_LOGIN=""
_REPO_NAME_SLUG=""
if command -v gh > /dev/null 2>&1; then
  _REPO_FULL="$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null | \
sed -E 's|.*[:/]([^/]+/[^/]+)(\.git)?$|\1|')" || true
  _REPO_OWNER_LOGIN="$(echo "$_REPO_FULL" | cut -d'/' -f1)"
  _REPO_NAME_SLUG="$(echo "$_REPO_FULL" | cut -d'/' -f2)"
fi

# 17. Conventional commit labels (idempotent — --force updates if already exists)
#     All creates are independent API calls — run them in parallel to cut label setup
#     time from ~4.5 s (9 × sequential round-trip) to ~500 ms.
if [ -n "$_REPO_FULL" ]; then
  gh label create "feat"     --repo "$_REPO_FULL" --description "New feature" \
    --color "0075ca" --force 2>/dev/null &
  gh label create "fix"      --repo "$_REPO_FULL" --description "Bug fix" \
    --color "d73a4a" --force 2>/dev/null &
  gh label create "chore"    --repo "$_REPO_FULL" --description "Maintenance, tooling, config" \
    --color "e4e669" --force 2>/dev/null &
  gh label create "docs"     --repo "$_REPO_FULL" --description "Documentation changes" \
    --color "0075ca" --force 2>/dev/null &
  gh label create "refactor" --repo "$_REPO_FULL" --description "Code restructuring, no behavior change" \
    --color "c5def5" --force 2>/dev/null &
  gh label create "perf"     --repo "$_REPO_FULL" --description "Performance improvement" \
    --color "0e8a16" --force 2>/dev/null &
  gh label create "test"     --repo "$_REPO_FULL" --description "Tests only" \
    --color "f9c74f" --force 2>/dev/null &
  gh label create "ci"       --repo "$_REPO_FULL" --description "CI/CD pipeline changes" \
    --color "000000" --force 2>/dev/null &
  gh label create "style"    --repo "$_REPO_FULL" --description "Formatting, whitespace" \
    --color "ffffff" --force 2>/dev/null &
  wait
  echo "  ✓ Conventional commit labels (feat, fix, chore, docs, refactor, perf, test, ci, style)"
fi

# 18. GitHub Project board (Todo → In Progress → In Review → Done)
#     Requires GH_PROJECT_PAT (classic PAT with 'project' scope) or gh auth that has project scope.
#     Skips silently and prints instructions instead if board creation fails.
_BOARD_CREATED=false
if [ -n "$_REPO_OWNER_LOGIN" ]; then
  _BOARD_NAME="${PROJECT_NAME:-${_REPO_NAME_SLUG} Roadmap}"

  # GraphQL queries use \$ (escaped dollar) inside double quotes so the $ signs are stored
  # as literals without triggering SC2016 (which fires on $ inside single-quoted strings).
  _GQL_GET_OWNER_ID="query(\$login:String!){user(login:\$login){id}}"
  _GQL_LIST_PROJECTS="query(\$login:String!){user(login:\$login){projectsV2(first:20){nodes{id,title}}}}"
  _GQL_CREATE_PROJECT="mutation(\$ownerId:ID!,\$title:String!)"
  _GQL_CREATE_PROJECT+="{createProjectV2(input:{ownerId:\$ownerId,title:\$title}){projectV2{id}}}"
  _GQL_GET_STATUS_FIELD="query(\$id:ID!){node(id:\$id){...on ProjectV2"
  _GQL_GET_STATUS_FIELD+="{field(name:\"Status\"){...on ProjectV2SingleSelectField{id}}}}}"
  _GQL_SET_STATUS_OPTIONS="mutation(\$fid:ID!){updateProjectV2Field(input:{fieldId:\$fid,"
  _GQL_SET_STATUS_OPTIONS+="singleSelectOptions:["
  _GQL_SET_STATUS_OPTIONS+="{name:\"Todo\",color:GRAY,description:\"\"},"
  _GQL_SET_STATUS_OPTIONS+="{name:\"In Progress\",color:BLUE,description:\"\"},"
  _GQL_SET_STATUS_OPTIONS+="{name:\"In Review\",color:YELLOW,description:\"PR open, awaiting review\"},"
  _GQL_SET_STATUS_OPTIONS+="{name:\"Done\",color:GREEN,description:\"\"}]"
  _GQL_SET_STATUS_OPTIONS+="}){projectV2Field{...on ProjectV2SingleSelectField{options{name}}}}}"

  _OWNER_NODE_ID="$(_gh_project api graphql \
    -f query="$_GQL_GET_OWNER_ID" \
    -f login="$_REPO_OWNER_LOGIN" \
    --jq '.data.user.id' 2>/dev/null || true)"

  if [ -n "$_OWNER_NODE_ID" ]; then
    # Idempotent guard — reuse the existing board if one with this name already exists.
    _NEW_PROJECT_ID="$(_gh_project api graphql \
      -f query="$_GQL_LIST_PROJECTS" \
      -f login="$_REPO_OWNER_LOGIN" \
      --jq ".data.user.projectsV2.nodes[] | select(.title == \"${_BOARD_NAME}\") | .id" \
      2>/dev/null | head -n1 || true)"

    if [ -z "$_NEW_PROJECT_ID" ]; then
      _NEW_PROJECT_ID="$(_gh_project api graphql \
        -f query="$_GQL_CREATE_PROJECT" \
        -f ownerId="$_OWNER_NODE_ID" \
        -f title="$_BOARD_NAME" \
        --jq '.data.createProjectV2.projectV2.id' 2>/dev/null || true)"
    fi

    if [ -n "$_NEW_PROJECT_ID" ]; then
      _STATUS_FIELD_ID="$(_gh_project api graphql \
        -f query="$_GQL_GET_STATUS_FIELD" \
        -f id="$_NEW_PROJECT_ID" \
        --jq '.data.node.field.id' 2>/dev/null || true)"

      if [ -n "$_STATUS_FIELD_ID" ]; then
        _gh_project api graphql \
          -f query="$_GQL_SET_STATUS_OPTIONS" \
          -f fid="$_STATUS_FIELD_ID" > /dev/null 2>&1 || true
        _BOARD_CREATED=true
        echo "  ✓ GitHub Project board: \"$_BOARD_NAME\" (Todo → In Progress → In Review → Done)"
      fi
    fi
  fi
fi

echo ""
echo "Done! Review the changes and commit them:"
echo "  cd $REPO_PATH"
echo "  git add -A && git commit -m 'chore: onboard agentic standards ($SORTED_STACK)'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "POST-ONBOARDING: Enable branch protection on the default branch"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Run the following commands from inside the target repo (requires admin access):"
echo ""
printf '%s\n' "  REPO_FULL=\"\$(git -C \"$REPO_PATH\" remote get-url origin | \
sed -E 's|.*[:/]([^/]+/[^/]+)(.git)?\$|\\1|')\""
echo "  DEFAULT_BRANCH=\"\$(git -C \"$REPO_PATH\" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | \
sed 's|.*/||' || echo main)\""
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

if [ "$_BOARD_CREATED" = false ]; then
  _BOARD_NAME_DISPLAY="${PROJECT_NAME:-${_REPO_NAME_SLUG:-<repo-name>} Roadmap}"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "POST-ONBOARDING: Create GitHub Project board"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Board creation requires a classic PAT with 'project' scope."
  echo "Fine-grained PATs do NOT have access to the Projects v2 API."
  echo ""
  echo "Option A — Re-run with a classic PAT:"
  echo "  export GH_PROJECT_PAT=<classic-pat-with-project-scope>"
  echo "  ./scripts/onboard-repo.sh --repo $REPO_PATH --stack $STACK"
  echo ""
  echo "Option B — Create the board manually on GitHub:"
  echo "  1. Go to https://github.com/${_REPO_OWNER_LOGIN:-<owner>}?tab=projects"
  echo "  2. Click 'New project' → select 'Board' layout"
  echo "  3. Name it: \"$_BOARD_NAME_DISPLAY\""
  echo "  4. Add Status columns: Todo → In Progress → In Review → Done"
  echo "  5. Link the repository to the project"
fi
