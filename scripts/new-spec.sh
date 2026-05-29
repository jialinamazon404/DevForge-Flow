#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Create a new spec template for a GitHub issue.

Usage: $0 <issue-number> [title]

If title is omitted, it will be auto-detected from: "gh issue view <N> --json title"
when gh is available.

Output:
  specs/issue-<N>/product.md
  specs/issue-<N>/tech.md

EOF
  exit 1
}

ISSUE="${1:-}"
TITLE="${2:-}"

if [ -z "$ISSUE" ]; then
  usage
fi

# Auto-detect title from gh if available and not provided
if [ -z "$TITLE" ]; then
  if command -v gh &>/dev/null; then
    TITLE=$(gh issue view "$ISSUE" --json title --jq '.title' 2>/dev/null || true)
  fi
fi
if [ -z "$TITLE" ]; then
  TITLE="Issue #${ISSUE}"
fi

SPEC_DIR="specs/issue-${ISSUE}"
mkdir -p "$SPEC_DIR"

PRODUCT_FILE="${SPEC_DIR}/product.md"
TECH_FILE="${SPEC_DIR}/tech.md"

TODAY=$(date +%Y-%m-%d)

if [ -f "$PRODUCT_FILE" ]; then
  echo "Error: $PRODUCT_FILE already exists" >&2
  exit 1
fi

cat > "$PRODUCT_FILE" <<PRODUCT
---
status: active
issue: ${ISSUE}
created_at: ${TODAY}
implemented_at:
implementation_pr:
deprecated_at:
deprecation_reason:
---

# Product Spec: ${TITLE}

## 1. Summary

<!-- One-paragraph summary of what this feature does and why it matters -->

## 2. Problem

<!-- What problem does this solve? Who is affected? What happens if we don't do this? -->

## 3. Goals

<!-- Bullet list of what this feature aims to achieve -->

## 4. Non-goals

<!-- What is explicitly out of scope for this feature -->

## 5. Figma / design references

<!-- Links to designs, mockups, or other visual references -->

## 6. User experience

<!-- How users interact with this feature: flows, edge cases, states -->

## 7. Success criteria

<!--
Checklist of acceptance criteria. Each item should be testable/verifiable.
-->

- [ ] Criterion 1
- [ ] Criterion 2

## 8. Validation

<!-- How to validate the implementation: testing strategy, edge cases, metrics -->

## 9. Open questions

<!-- Anything unresolved that needs discussion -->
PRODUCT

cat > "$TECH_FILE" <<TECH
# Tech Spec: ${TITLE}

## 1. Problem

## 2. Relevant code

## 3. Current state

## 4. Proposed changes

## 5. Migration / compatibility

## 6. Testing strategy

## 7. Open questions
TECH

echo "Created:"
echo "  $PRODUCT_FILE"
echo "  $TECH_FILE"
