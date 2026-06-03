#!/usr/bin/env bash
# update.sh — Update AICodingFlow in an already-installed project
# This script is synced into scripts/ by install.sh and can be run
# from the target project at any time.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: update.sh [--check] [--dry-run] [--only <component>] [--auto-commit] [--upgrade-mode <mode>]

Update AICodingFlow files in this project to the latest upstream version.

Options:
  --check            Only check for available updates; do not apply them.
                     Prints current version, latest version, and change list.
  --dry-run          Preview what would be updated without writing files.
  --only <component> Only update the specified component:
                     - skills    .agents/skills/ (core skills only)
                     - workflows  .github/workflows/ (managed workflows)
                     - scripts    .github/scripts/ + scripts/
  --auto-commit      After updating, automatically create a git commit
                     with a summary of changes.
  --upgrade-mode <mode>  Switch installation mode during update:
                     - full      Upgrade from lite to full (installs AI workflows
                                 and rewrites ci.yml with ai-review job).
                                 Requires AGENT_API_KEY to be configured.
                     - lite      Downgrade from full to lite (removes AI workflows
                                 and rewrites ci.yml without ai-review job).
  -h, --help         Show this help message.

Examples:
  # Check if updates are available
  ./scripts/update.sh --check

  # Preview what would change
  ./scripts/update.sh --dry-run

  # Update everything (interactive)
  ./scripts/update.sh

  # Update only skills
  ./scripts/update.sh --only skills

  # Update and auto-commit
  ./scripts/update.sh --auto-commit
USAGE
}

fail() { printf 'update.sh: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

# --- Configuration ---
UPSTREAM_REPO="${AICODINGFLOW_UPSTREAM_REPO:-https://github.com/jialinamazon404/DevForge-Flow.git}"
VERSION_FILE=".aicodingflow-version"
AI_WORKFLOWS=(
  "triage-issue.yml"
  "create-spec-from-issue.yml"
  "create-implementation-from-issue.yml"
  "review-pr.yml"
  "verify-impl-against-spec.yml"
  "respond-to-pr-comment.yml"
  "update-pr-review.yml"
  "update-dedupe.yml"
)
NON_AI_WORKFLOWS=(
  "plan-approved.yml"
  "archive-spec.yml"
  "generate-project-history.yml"
)

# --- Parse arguments ---
action="update"
dry_run=false
only_component=""
auto_commit=false
upgrade_mode=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)   action="check"; shift ;;
    --dry-run) dry_run=true; shift ;;
    --only)
      [ "$#" -ge 2 ] || fail "--only requires a component (skills|workflows|scripts)"
      only_component="$2"; shift 2 ;;
    --upgrade-mode)
      [ "$#" -ge 2 ] || fail "--upgrade-mode requires a mode (full|lite)"
      upgrade_mode="$2"; shift 2 ;;
    --auto-commit) auto_commit=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown option: $1" ;;
  esac
done

# --- Locate project root ---
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -f "$project_root/.agents/AGENTS.md" ] || \
  fail "AICodingFlow is not installed in this project. Run install.sh first."

cd "$project_root"

# --- Detect current installation ---
current_version="unknown"
current_mode="unknown"

if [ -f "$VERSION_FILE" ]; then
  current_version="$(sed -n 's/^version: //p' "$VERSION_FILE" | head -1)"
  current_mode="$(sed -n 's/^mode: //p' "$VERSION_FILE" | head -1)"
fi

# Check mode by counting AI workflows
has_ai_wf=false
for wf in "${AI_WORKFLOWS[@]}"; do
  if [ -f ".github/workflows/$wf" ]; then has_ai_wf=true; break; fi
done
if [ "$has_ai_wf" = true ]; then current_mode="full"; else current_mode="lite"; fi

# --- Apply --upgrade-mode override ---
if [ -n "$upgrade_mode" ]; then
  case "$upgrade_mode" in
    full|lite) ;;
    *) fail "unknown upgrade mode: $upgrade_mode (use full|lite)" ;;
  esac
  if [ "$upgrade_mode" = "$current_mode" ]; then
    info "Already in $current_mode mode. No mode change needed."
  else
    info "Switching mode: $current_mode → $upgrade_mode"
    current_mode="$upgrade_mode"
  fi
fi

# --- Fetch upstream ---
command -v git >/dev/null 2>&1 || fail "git is required"
command -v rsync >/dev/null 2>&1 || fail "rsync is required"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

info "Fetching latest AICodingFlow from $UPSTREAM_REPO ..."
git clone --depth 1 "$UPSTREAM_REPO" "$tmpdir/AICodingFlow" >/dev/null 2>&1

upstream_dir="$tmpdir/AICodingFlow"

# --- Detect upstream version ---
latest_version="unknown"
if [ -f "$upstream_dir/$VERSION_FILE" ]; then
  latest_version="$(sed -n 's/^version: //p' "$upstream_dir/$VERSION_FILE" | head -1)"
elif [ -f "$upstream_dir/install.sh" ]; then
  # Fallback: use git commit hash
  latest_version="$(git -C "$upstream_dir" rev-parse --short HEAD)"
fi

# --- Check action: just report ---
if [ "$action" = "check" ]; then
  info ""
  info "=== AICodingFlow Update Check ==="
  info "Current version:  $current_version"
  info "Latest version:   $latest_version"
  info "Current mode:     $current_mode"
  info ""

  if [ "$current_version" = "$latest_version" ]; then
    info "You are already on the latest version. No update needed."
    exit 0
  fi

  info "Changes available:"
  info ""

  # Compare skills
  for skill in "$upstream_dir/.agents/skills"/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    [[ "$name" == *-repo ]] && continue
    dest=".agents/skills/$name"
    if [ ! -d "$dest" ]; then
      info "  [NEW]     .agents/skills/$name/"
    elif ! diff -rq "$skill" "$dest" >/dev/null 2>&1; then
      info "  [CHANGED] .agents/skills/$name/"
    fi
  done

  # Compare workflows
  for wf_dir in "$upstream_dir/.github/workflows"/*.yml; do
    [ -f "$wf_dir" ] || continue
    wf="$(basename "$wf_dir")"
    dest=".github/workflows/$wf"
    # Skip ci.yml (user-managed)
    [ "$wf" = "ci.yml" ] && continue
    # Skip AI workflows in lite mode
    if [ "$current_mode" = "lite" ]; then
      skip=false
      for ai_wf in "${AI_WORKFLOWS[@]}"; do
        [ "$wf" = "$ai_wf" ] && skip=true && break
      done
      [ "$skip" = true ] && continue
    fi
    if [ ! -f "$dest" ]; then
      info "  [NEW]     .github/workflows/$wf"
    elif ! diff -q "$wf_dir" "$dest" >/dev/null 2>&1; then
      info "  [CHANGED] .github/workflows/$wf"
    fi
  done

  # Compare scripts
  for script_dir in scripts .github/scripts .github/aicodingflow-tests; do
    src="$upstream_dir/$script_dir"
    [ -d "$src" ] || continue
    for f in "$src"/*; do
      [ -f "$f" ] || continue
      fname="$(basename "$f")"
      dest="$project_root/$script_dir/$fname"
      rel="$script_dir/$fname"
      if [ ! -f "$dest" ]; then
        info "  [NEW]     $rel"
      elif ! diff -q "$f" "$dest" >/dev/null 2>&1; then
        info "  [CHANGED] $rel"
      fi
    done
  done

  info ""
  info "To apply updates, run: ./scripts/update.sh"
  info "To preview first:      ./scripts/update.sh --dry-run"
  exit 0
fi

# --- Update action ---
info ""
info "=== AICodingFlow Update ==="
info "Current: $current_version → Latest: $latest_version"
info "Mode: $current_mode"
info ""

# Count changes
change_count=0

copy_dir() {
  local src="$1"
  local dest="$2"
  shift 2
  if [ "$dry_run" = true ]; then
    info "  Would sync $src -> $dest"
    change_count=$((change_count + 1))
  else
    mkdir -p "$dest"
    rsync -a "$@" "$src/" "$dest/"
    change_count=$((change_count + 1))
  fi
}

# --- Selective update logic ---
update_skills=false
update_workflows=false
update_scripts=false

if [ -z "$only_component" ]; then
  update_skills=true
  update_workflows=true
  update_scripts=true
else
  case "$only_component" in
    skills)    update_skills=true ;;
    workflows) update_workflows=true ;;
    scripts)   update_scripts=true ;;
    *) fail "unknown component: $only_component (use skills|workflows|scripts)" ;;
  esac
fi

# --- Update Skills ---
if [ "$update_skills" = true ]; then
  info "Updating skills ..."
  skills_src="$upstream_dir/.agents/skills"
  skills_dest=".agents/skills"
  mkdir -p "$skills_dest"

  for skill in "$skills_src"/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    dest="$skills_dest/$name"

    # Always skip repo-local companion skills
    if [[ "$name" == *-repo ]]; then
      info "  Preserving your companion skill: .agents/skills/$name/"
      continue
    fi

    copy_dir "$skill" "$dest"
  done
fi

# --- Update Workflows ---
if [ "$update_workflows" = true ]; then
  info "Updating workflows ..."
  wf_src="$upstream_dir/.github/workflows"
  wf_dest=".github/workflows"
  mkdir -p "$wf_dest"

  excludes=("--exclude" "ci.yml")
  if [ "$current_mode" = "lite" ]; then
    for ai_wf in "${AI_WORKFLOWS[@]}"; do
      excludes+=("--exclude" "$ai_wf")
    done
  fi
  copy_dir "$wf_src" "$wf_dest" "${excludes[@]}"
fi

# --- Handle ci.yml for mode upgrade ---
if [ -n "$upgrade_mode" ] && [ "$dry_run" = false ]; then
  ci_dest=".github/workflows/ci.yml"
  if [ "$upgrade_mode" = "full" ] && [ -f "$upstream_dir/.github/workflows/ci.yml" ]; then
    mkdir -p "$(dirname "$ci_dest")"
    cp "$upstream_dir/.github/workflows/ci.yml" "$ci_dest"
    info "  Replaced ci.yml with full mode version (includes ai-review job)"
  elif [ "$upgrade_mode" = "lite" ]; then
    mkdir -p "$(dirname "$ci_dest")"
    cat > "$ci_dest" <<'CI_LITE'
name: CI

on:
  pull_request:
    types: [opened, reopened, synchronize, ready_for_review]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  test:
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    env:
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: "true"

    steps:
      - name: Checkout
        uses: actions/checkout@v6
        with:
          fetch-depth: 1

      - name: Run repository unit tests
        run: python3 -m unittest discover -s .github/tests

      - name: Run delivered unit tests
        run: python3 -m unittest discover -s .github/aicodingflow-tests

      - name: Compile Python scripts
        run: |
          PYTHONPYCACHEPREFIX=/tmp/aicodingflow-pycache python3 -m py_compile \
            .github/scripts/*.py \
            .agents/skills/implement-specs/scripts/*.py \
            .agents/skills/review-pr/scripts/validate_review_json.py \
            .agents/skills/update-pr-review/scripts/*.py \
            .agents/skills/update-dedupe/scripts/*.py
CI_LITE
    info "  Replaced ci.yml with lite mode version (no ai-review job)"
  fi
fi

# --- Update Scripts ---
if [ "$update_scripts" = true ]; then
  info "Updating scripts ..."
  for dirname in scripts .github/scripts .github/aicodingflow-tests; do
    src="$upstream_dir/$dirname"
    [ -d "$src" ] || continue
    dest="$project_root/$dirname"
    copy_dir "$src" "$dest"
  done
fi

# --- Update AGENTS.md (non-destructive: only if upstream has changes) ---
if [ -z "$only_component" ] || [ "$only_component" = "skills" ]; then
  upstream_agents="$upstream_dir/.agents/AGENTS.md"
  local_agents=".agents/AGENTS.md"
  if [ -f "$upstream_agents" ] && [ -f "$local_agents" ]; then
    if ! diff -q "$upstream_agents" "$local_agents" >/dev/null 2>&1; then
      if [ "$dry_run" = true ]; then
        info "  Would update .agents/AGENTS.md"
      else
        # Preserve local Project Context section if it exists
        local_context=""
        if grep -q "^## Project Context" "$local_agents" 2>/dev/null; then
          local_context="$(sed -n '/^## Project Context/,$ p' "$local_agents")"
        fi

        # Write upstream version, then append local context
        cp "$upstream_agents" "$local_agents"
        if [ -n "$local_context" ]; then
          printf '\n%s\n' "$local_context" >> "$local_agents"
          info "  Updated .agents/AGENTS.md (preserved your Project Context)"
        else
          info "  Updated .agents/AGENTS.md"
        fi
        change_count=$((change_count + 1))
      fi
    fi
  fi
fi

# --- Merge .gitignore entries (append-only, never remove user entries) ---
if [ -z "$only_component" ]; then
  upstream_gitignore="$upstream_dir/.gitignore"
  target_gitignore=".gitignore"
  if [ -f "$upstream_gitignore" ]; then
    if [ "$dry_run" = true ]; then
      info "  Would merge .gitignore entries"
    else
      added=0
      while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^# ]] && continue
        if [ -f "$target_gitignore" ] && grep -qF "$line" "$target_gitignore" 2>/dev/null; then
          continue
        fi
        echo "$line" >> "$target_gitignore"
        added=$((added + 1))
      done < "$upstream_gitignore"
      if [ "$added" -gt 0 ]; then
        info "  Merged $added .gitignore entries"
        change_count=$((change_count + 1))
      fi
    fi
  fi
fi

# --- Update version file ---
if [ "$dry_run" = false ]; then
  cat > "$VERSION_FILE" <<EOF
version: $latest_version
mode: $current_mode
updated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  info ""
  info "Version file updated: $VERSION_FILE"
fi

# --- Post-update summary ---
if [ "$dry_run" = true ]; then
  info ""
  info "Dry run complete. No files were written."
  info "To apply: ./scripts/update.sh"
  exit 0
fi

info ""
info "=== Update Complete ==="
info "Updated to: $latest_version"
info "Changes applied: $change_count items"
info ""

# --- Auto-commit ---
if [ "$auto_commit" = true ]; then
  # Stage only AICodingFlow-managed paths
  git add \
    .agents/skills/ \
    .agents/AGENTS.md \
    .github/workflows/ \
    .github/scripts/ \
    .github/aicodingflow-tests/ \
    scripts/ \
    "$VERSION_FILE"

  # Check if there's anything to commit
  if git diff --cached --quiet; then
    info "No changes to commit (files were identical)."
  else
    git commit -m "$(cat <<COMMITMSG
chore: update AICodingFlow to $latest_version

Updated via scripts/update.sh.
Companion skills (*-repo) were preserved.
ci.yml was not overwritten.

🤖 Generated with [Qoder][https://qoder.com]
COMMITMSG
)"
    info "Auto-committed update to git."
  fi
else
  info "Review changes with: git diff"
  info "Commit manually or re-run with --auto-commit"
fi

info ""
info "Post-update checklist:"
info "  1. Check git diff for any overwritten customizations"
info "  2. If you modified a managed workflow, restore it with git checkout"
info "  3. Run \$project-init in your AI tool to refresh project context"
info "  4. Companion skills (*-repo) were NOT overwritten — safe"
info "  5. ci.yml was NOT overwritten — safe"