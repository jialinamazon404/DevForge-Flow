---
name: init-spec
description: Create product.md and tech.md spec templates for a GitHub issue under specs/issue-<N>/. Use when the user says "init spec", "create spec template", "new spec", "scaffold spec for issue N", or wants to set up spec files before writing content.
---

# init-spec

Create spec template files (`product.md` + `tech.md`) under `specs/issue-<N>/` for a given GitHub issue.

## When to use

Use this skill when the user wants to:

- scaffold spec templates for an issue before writing content
- create the `specs/issue-<N>/` directory structure with proper YAML frontmatter
- prepare blank product.md and tech.md for manual or AI-assisted editing

Do not use this skill for writing spec content (use `$write-product-spec` / `$write-tech-spec`), implementing features, or reviewing specs.

## Input

Extract the issue number from the user's request. Accept formats like `#42`, `42`, or `issue 42`. An optional title can follow; if omitted, it will be auto-detected from `gh issue view` when `gh` is available.

Examples:
- `$init-spec #42`
- `$init-spec 42 "Add OAuth2 authentication"`

## Steps

1. **Parse input** — extract `<issue-number>` and optional `[title]` from the user's message.

2. **Check for existing specs** — verify `specs/issue-<N>/product.md` does not already exist. If it does, warn the user and stop (do not overwrite).

3. **Run the script**:

   ```bash
   bash scripts/new-spec.sh <issue-number> [title]
   ```

4. **Verify output** — confirm both files were created:
   - `specs/issue-<N>/product.md`
   - `specs/issue-<N>/tech.md`

5. **Report results** — show the user:
   - The paths of the created files
   - A brief summary of the template structure (sections in each file)
   - Suggest next steps: fill in the spec content manually, or use `$write-product-spec` / `$write-tech-spec` for AI-assisted spec writing

## Error handling

- If `scripts/new-spec.sh` does not exist, report that the script is missing and suggest the user check their AICodingFlow installation.
- If the spec directory already exists, do not overwrite — warn and stop.
- If `gh` is not available and no title is provided, use `Issue #<N>` as the title.

## Security rules

- This skill only creates files under `specs/`. It does not modify any source code.
- No git operations are performed.
- No remote API calls are made (except optional `gh issue view` for title detection).
