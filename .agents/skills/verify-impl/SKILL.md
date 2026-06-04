---
name: verify-impl
description: Verify implementation against spec by comparing git diff with acceptance criteria and expected file changes. Use when the user says "verify implementation", "check spec alignment", "verify issue N", or wants to validate code changes against a spec before committing or creating a PR.
---

# verify-impl

Compare the current branch's code changes against the spec for a given issue and produce a verification report.

## When to use

Use this skill when the user wants to:

- check whether implementation matches the product spec's acceptance criteria
- compare actual file changes against the tech spec's expected changes
- generate a verification report before committing or creating a PR
- identify gaps between spec and implementation

Do not use this skill for writing specs, implementing features, or creating PRs.

## Input

Extract the issue number from the user's request. Accept formats like `#42`, `42`, or `issue 42`. An optional `--base <ref>` can be provided (defaults to `main`).

Examples:
- `$verify-impl #42`
- `$verify-impl 42 --base develop`

## Steps

1. **Parse input** — extract `<issue-number>` and optional `[--base <ref>]`.

2. **Verify spec exists** — check that `specs/issue-<N>/product.md` exists. If not, suggest running `$init-spec` first.

3. **Run the verification script**:

   ```bash
   python3 scripts/verify-impl.py <issue-number> [--base <ref>]
   ```

4. **Present the report** — display the full verification report to the user, including:
   - Acceptance criteria checklist (unchecked for manual verification)
   - File change comparison (matched vs unmatched)
   - Diff summary statistics

5. **Suggest next steps** based on the results:
   - If files are missing from the diff: point out which expected files were not changed
   - If all criteria look good: suggest `$git-commit` and `$create-pr`
   - If spec needs updating: suggest editing the spec files directly

## Error handling

- If `scripts/verify-impl.py` is missing, report the error and suggest the user check their AICodingFlow installation.
- If `git diff` fails (e.g., no commits yet on the branch), report that and suggest making at least one commit first.
- If the spec has no structured acceptance criteria, note that in the report and suggest the user add some.

## Security rules

- This skill is read-only. It does not modify any files.
- No git mutations (no commit, push, or branch operations).
- No remote API calls.
