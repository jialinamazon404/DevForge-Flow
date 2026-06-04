---
name: archive-spec
description: Archive a spec by updating its YAML frontmatter status to implemented or deprecated. Use when the user says "archive spec", "mark spec as implemented", "deprecate spec", "close spec for issue N", or after a PR has been merged and the spec should be closed.
---

# archive-spec

Update the YAML frontmatter status of a spec to `implemented` or `deprecated`.

## When to use

Use this skill when the user wants to:

- mark a spec as implemented after a PR is merged
- deprecate a spec that is no longer needed
- update the spec's status metadata in the YAML frontmatter

Do not use this skill for creating specs, writing specs, or implementing features.

## Input

Extract from the user's request:

- **issue number** (required) — formats like `#42`, `42`, or `issue 42`
- **status** (required) — either `implemented` or `deprecated`
- **value** (optional) — PR number for `implemented` (e.g., `123` or `#123`), or a reason string for `deprecated`

Examples:
- `$archive-spec #42 implemented 123`
- `$archive-spec #42 deprecated "Feature cancelled by stakeholder"`

## Steps

1. **Parse input** — extract issue number, status, and optional value.

2. **Verify spec exists** — check that `specs/issue-<N>/product.md` exists. If not, report that no spec was found for this issue.

3. **Confirm action** — before modifying, show the user what will change:
   - Current status (read from existing frontmatter)
   - New status and associated metadata
   - Ask for confirmation if the status is `deprecated`

4. **Run the archive script**:

   ```bash
   python3 scripts/archive-spec.py <issue-number> <status> [value]
   ```

5. **Verify and report** — read the updated file and confirm the frontmatter was updated correctly. Show the user:
   - Updated status
   - Implementation PR number (if applicable)
   - Deprecation reason (if applicable)
   - Suggest committing the change with `$git-commit`

## Error handling

- If `scripts/archive-spec.py` is missing, report the error and suggest the user check their AICodingFlow installation.
- If an invalid status is provided, only accept `implemented` or `deprecated` — reject anything else.
- If the spec is already in the target status, warn and skip.

## Security rules

- This skill only modifies the YAML frontmatter of `specs/issue-<N>/product.md`. It does not touch source code.
- No git operations are performed (the user should commit the change separately).
- No remote API calls.
