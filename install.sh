#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install.sh [--target <path>] [--lite] [--dry-run]

Install AICodingFlow files into a target repository.

Options:
  --target <path>   Target repository path. Defaults to the current directory.
  --lite            Install lite mode: only non-AI workflows (CI tests, spec
                    archive, plan-approved, project-history) and a lite CI
                    (no ai-review job). Skills and local scripts are still
                    included for local OpenCode/Qoder usage. No AGENT_API_KEY
                    is required.
                    (--local is accepted as an alias for --lite)
  --dry-run         Print planned copies and skips without writing files.
  -h, --help        Show this help message.

Examples:
  # Full install (all workflows including AI)
  ./install.sh --target /path/to/repo

  # Lite install (non-AI workflows only, no AGENT_API_KEY needed)
  ./install.sh --target /path/to/repo --lite

  # Dry run to preview
  ./install.sh --target /path/to/repo --dry-run
  ./install.sh --target /path/to/repo --lite --dry-run

  curl -fsSL https://github.com/jialinamazon404/DevForge-Flow/main/install.sh | bash -s -- --target /path/to/repo
  curl -fsSL https://github.com/jialinamazon404/DevForge-Flow/main/install.sh | bash -s -- --target /path/to/repo --lite
USAGE
}

fail() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="$(pwd)"
dry_run=false
lite_mode=false
install_repository="${AICODINGFLOW_INSTALL_REPOSITORY:-https://github.com/jialinamazon404/DevForge-Flow.git}"

# AI-dependent workflow files that require AGENT_API_KEY + opencode action
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

is_source_tree() {
  [ -f "$script_dir/install.sh" ] &&
    [ -f "$script_dir/.agents/AGENTS.md" ] &&
    [ -d "$script_dir/.agents/skills" ] &&
    [ -d "$script_dir/.github/workflows" ]
}

if ! is_source_tree; then
  command -v git >/dev/null 2>&1 || fail "git is required for remote installation"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  git clone --depth 1 "$install_repository" "$tmpdir/AICodingFlow" >/dev/null
  bash "$tmpdir/AICodingFlow/install.sh" "$@"
  exit $?
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || fail "--target requires a path"
      target_dir="$2"
      shift 2
      ;;
    --lite|--local)
      lite_mode=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      target_dir="$1"
      shift
      ;;
  esac
done

command -v rsync >/dev/null 2>&1 || fail "rsync is required but was not found"

[ -d "$target_dir" ] || fail "target path is not a directory: $target_dir"
[ -d "$script_dir/.agents/skills" ] || fail "source .agents/skills directory is missing"

target_dir="$(cd "$target_dir" && pwd)"

copy_dir() {
  local src="$1"
  local dest="$2"
  shift 2

  if [ "$dry_run" = true ]; then
    info "Would sync $src -> $dest"
  else
    mkdir -p "$dest"
    rsync -a "$@" "$src/" "$dest/"
  fi
}

sync_skills() {
  local skills_src="$script_dir/.agents/skills"
  local skills_dest="$target_dir/.agents/skills"
  local skill name dest

  if [ "$dry_run" = false ]; then
    mkdir -p "$skills_dest"
  fi

  for skill in "$skills_src"/*; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    dest="$skills_dest/$name"

    if [[ "$name" == *-repo ]]; then
      info "Skipping repo-local companion skill: .agents/skills/$name/SKILL.md"
      continue
    fi

    copy_dir "$skill" "$dest"
  done
}

sync_github_dirs() {
  local dirname src dest excludes

  for dirname in scripts aicodingflow-tests workflows; do
    src="$script_dir/.github/$dirname"
    [ -d "$src" ] || continue
    dest="$target_dir/.github/$dirname"

    if [ "$dirname" = "workflows" ]; then
      excludes=("--exclude" "ci.yml")
      if [ "$lite_mode" = true ]; then
        for ai_wf in "${AI_WORKFLOWS[@]}"; do
          excludes+=("--exclude" "$ai_wf")
        done
      fi
      copy_dir "$src" "$dest" "${excludes[@]}"
    else
      copy_dir "$src" "$dest"
    fi
  done
}

write_ci_lite() {
  local ci_dest="$target_dir/.github/workflows/ci.yml"
  if [ "$dry_run" = true ]; then
    info "Would write lite ci.yml (no ai-review job) to $ci_dest"
    return
  fi
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
  info "Written lite ci.yml (no ai-review job) to $ci_dest"
}

sync_skills
sync_github_dirs

if [ "$lite_mode" = true ]; then
  write_ci_lite
fi

if [ "$dry_run" = true ]; then
  info "Dry run complete. No files were written."
elif [ "$lite_mode" = true ]; then
  info "AICodingFlow lite installation complete (no AI workflows)."
else
  info "AICodingFlow installation complete."
fi

if [ "$lite_mode" = true ]; then
  cat <<'NEXT_LITE'

Installed in lite mode (--lite).

Available workflows:
  - ci.yml (test + compile only, no ai-review job)
  - plan-approved.yml
  - archive-spec.yml
  - generate-project-history.yml

Not installed (require AGENT_API_KEY + opencode action):
  - triage-issue.yml, create-spec-from-issue.yml
  - create-implementation-from-issue.yml, review-pr.yml
  - verify-impl-against-spec.yml, respond-to-pr-comment.yml
  - update-pr-review.yml, update-dedupe.yml

To upgrade to full mode later, re-run install.sh without
--lite and configure AGENT_API_KEY + AGENT_MODEL + AGENT_LOGIN
in your repository Settings > Secrets and Variables.
NEXT_LITE
else
  cat <<'NEXT'

Optional next step for first-time issue triage setup:
$bootstrap-issue-config

This optional bootstrap uses the GitHub CLI and may create labels or update .github/CODEOWNERS.
It is intended for first-time triage setup, not regular scheduled runs.
NEXT
fi
