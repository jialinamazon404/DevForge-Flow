---
name: spec-search
description: Search and list specs in the repository by keyword, issue number, area, or listing all specs. Use when the user asks "what specs exist", "find specs about X", "search specs for keyword Y", or wants to discover past feature plans.
---

# spec-search

Search and list specs from the `specs/` directory.

## When to use

Use this skill when the user wants to:

- list all specs in the repository
- find specs related to a topic, keyword, or area
- check the status of a specific spec
- discover what features or changes have been spec'd in the past
- find spec files for a given issue number

Do not use this skill for implementation, writing new specs, or reviewing existing
specs. Those use `write-product-spec`, `write-tech-spec`, `review-spec`, and
`implement-specs` respectively.

## How to search

Use these methods depending on what the user wants:

### List all specs

```bash
glob specs/issue-*/product.md
```

For each match, read the first line (`# Title`) and the Summary section to
build a summary table.

### Search by keyword

```bash
rg -l -i "<keyword>" specs/issue-*/product.md specs/issue-*/tech.md
```

Read the matching files to understand context. Present only the relevant
matches.

### Find by issue number

```bash
glob specs/issue-<N>/product.md
glob specs/issue-<N>/tech.md
```

Read both files when they exist.

### Filter by area or topic

Use keyword search with area-related terms since there is no structured metadata
yet. For example:

```bash
rg -l -i "workflow" specs/issue-*/product.md
rg -l -i "review" specs/issue-*/product.md
rg -l -i "skill" specs/issue-*/product.md
```

## Output format

### Summary table (listing multiple specs)

```markdown
| Issue | Title | Summary |
|-------|-------|---------|
| #N   | spec title | one-sentence summary |
```

Keep the summary to one line. Omit or truncate when the spec title alone is
informative enough.

### Detail view (single spec)

```markdown
### #N — spec title

**Issue:** #N
**Files:** `specs/issue-N/product.md`, `specs/issue-N/tech.md` (if tech spec exists)

Summary from the spec's `## 1. Summary` section.
```

### No results

When no matching spec is found, report that clearly:

```
No matching specs found for "<keyword>".
```

Suggest trying related terms or listing all specs if the user has a broader
question.

## Limitations

- There is no structured metadata (YAML frontmatter) in existing specs yet.
  Search relies on file glob patterns and full-text grep.
- Status tracking (draft, review, approved, implemented) is not available until
  frontmatter is added to spec files. All existing specs are listed without
  a computed status.
- The skill only searches `specs/` directory. It does not search outside
  the specs directory.
