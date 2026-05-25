# DevForge-Flow Conventions

This document defines all conventions, schemas, and best practices for DevForge-Flow (AICodingFlow). It serves as the authoritative reference for developers and AI agents working within this workflow system.

## Table of Contents

- [Git Conventions](#git-conventions)
- [Label System](#label-system)
- [Spec Conventions](#spec-conventions)
- [PR Conventions](#pr-conventions)
- [Workflow Triggers](#workflow-triggers)
- [JSON Schemas](#json-schemas)
- [Best Practices](#best-practices)
- [Companion Skills Writing Guide](#companion-skills-writing-guide)

---

## Git Conventions

### Branch Naming

**Format:** `<type>/<short-desc>-<issueID>`

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature or capability | `feat/add-retry-logic-42` |
| `fix` | Bug fix | `fix/handle-null-input-15` |
| `refactor` | Code restructuring without behavior change | `refactor/simplify-auth-module-33` |
| `docs` | Documentation changes | `docs/update-readme-7` |
| `test` | Adding or updating tests | `test/add-unit-tests-21` |
| `perf` | Performance improvements | `perf/optimize-query-55` |
| `chore` | Maintenance tasks | `chore/update-dependencies-12` |
| `spec` | Spec-only changes (no code) | `spec/define-api-structure-99` |
| `impl` | Implementation from spec | `impl/add-auth-flow-99` |

**Rules:**
- Issue-backed branches must include the issue ID suffix
- Non-issue branches use `<type>/<user-provided-name>` (never invent an issue ID)
- Description must be short lowercase English words separated by hyphens
- Remove punctuation, filler words, repeated separators, and non-branch characters

**Validation:**
```bash
git check-ref-format --branch <branch-name>
```

### Commit Format

**Format:** Conventional Commits

```text
type(scope): summary

[optional body]

Refs #<issueID>
```

**Types:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`

**Issue Linking:**
- Use `Fixes #123` only when the commit definitively closes the issue
- Use `Refs #123` for partial, preparatory, docs-only, or cleanup work
- Do not invent issue IDs

**Examples:**

```text
feat(auth): add OAuth2 support

Refs #42

fix(api): handle null response from upstream service

Fixes #15

docs(conventions): document branch naming rules

Refs #7
```

**Avoid:** `update`, `changes`, `misc`, `wip` as commit types

---

## Label System

### Protected Labels

These labels control critical workflow transitions and cannot be auto-added or auto-removed by triage automation:

| Label | Color | Purpose |
|-------|-------|---------|
| `ready-to-spec` | `#1D76DB` | Issue is ready for spec creation |
| `ready-to-implement` | `#0E8A16` | Spec is approved, ready for implementation |
| `plan-approved` | `#5319E7` | Implementation plan has been approved |

**Rules:**
- Triage workflows must never include these labels in `labels` output
- Only human review/approval can add or remove these labels
- These labels gate spec-to-implementation transitions

### Flow Labels

| Label | Color | Purpose |
|-------|-------|---------|
| `triaged` | `#C2E0C6` | Issue has been reviewed and categorized |
| `needs-info` | `#D876E3` | More information needed before progress |
| `duplicate` | `#CFD3D7` | Issue identified as duplicate |
| `ready-for-review` | - | PR ready for human review |

### Reproducibility Labels

| Label | Color | Purpose |
|-------|-------|---------|
| `repro:high` | `#B60205` | High-confidence or easily reproducible |
| `repro:medium` | `#FBCA04` | Moderate-confidence or partially reproducible |
| `repro:low` | `#C5DEF5` | Low-confidence or hard-to-reproduce |
| `repro:unknown` | `#CFD3D7` | Insufficient information to estimate |

### Area Labels

| Label | Color | Purpose |
|-------|-------|---------|
| `area:workflow` | `#7057FF` | GitHub workflows and Python automation scripts |
| `area:skills` | `#D4C5F9` | Codex skills and agent behavior guidance |
| `area:specs` | `#0075CA` | Product specs, technical specs, and spec-driven workflows |
| `area:tests` | `#BFDADC` | Automated tests and test fixtures |

### Type Labels

| Label | Color | Purpose |
|-------|-------|---------|
| `bug` | `#D73A4A` | Something is not working as expected |
| `enhancement` | `#A2EEEF` | New capability or improvement request |
| `documentation` | `#0075CA` | Documentation or guidance update |
| `question` | `#D876E3` | Issue is primarily a question or discussion |
| `invalid` | `#E4E669` | Issue does not describe a valid task |
| `wontfix` | `#FFFFFF` | Issue will not be worked on |

### Helper Labels

| Label | Color | Purpose |
|-------|-------|---------|
| `good first issue` | `#7057FF` | Issue suitable for a first contribution |
| `help wanted` | `#008672` | Extra maintainer attention needed |

---

## Spec Conventions

### Directory Structure

```
specs/
├── issue-<N>/          # Specs for issue #N
│   ├── product.md      # Product spec (behavior, UX, validation)
│   └── tech.md         # Tech spec (architecture, implementation)
└── ...
```

### Product Spec Sections

Every `product.md` must include these sections:

1. **Summary** - Brief feature description and desired outcome
2. **Problem** - User or product problem being solved
3. **Goals** - Required outcomes this change must achieve
4. **Non-goals** - Explicitly out-of-scope items
5. **Figma / design references** - Link or explicit note of absence
6. **User experience** - Concrete, exhaustive, testable behavior description:
   - Default behavior
   - State transitions
   - Edge cases
   - Empty states
   - Error states
   - Keyboard/interaction expectations
7. **Success criteria** - Observable outcomes that define correctness
8. **Validation** - Verification methods (tests, screenshots, manual steps)
9. **Open questions** - Unresolved product decisions

### Tech Spec Sections

Every `tech.md` must include these sections:

1. **Problem** - Technical problem and relation to product behavior
2. **Relevant code** - Key files, types, and entry points with line numbers
3. **Current state** - How the system works today and limitations
4. **Proposed changes** - Implementation plan with:
   - Modules/components that change
   - New types, APIs, or state
   - Data flow and event flow
   - Ownership boundaries
   - Pattern alignment
5. **End-to-end flow** - Path through system for main interaction
6. **Risks and mitigations** - Failure modes, regressions, rollout hazards
7. **Testing and validation** - Tests and verification needed
8. **Follow-ups** - Deferred cleanup, extensions, future work

### Spec Lifecycle

1. Issue labeled `ready-to-spec` → workflow creates `specs/issue-<N>/product.md` and `tech.md`
2. Human reviews spec PR → approves or requests changes
3. Spec PR merged → issue labeled `plan-approved`
4. Issue meets implementation gates → labeled `ready-to-implement`
5. Implementation proceeds → specs updated as behavior evolves
6. Final PR merged → specs reflect shipped behavior

---

## PR Conventions

### Title Format

```text
[#123] type(scope): summary
```

**Examples:**
- `[#42] feat(auth): add OAuth2 support`
- `[#15] fix(api): handle null response`
- `[#7] docs: update conventions`

### Summary Template

PR description must include:

```markdown
## What
[One-line description of the change]

## Why
[Reason for the change, problem being solved]

## How
[Key implementation details]

## Testing
[How this was tested]
```

### Metadata File

When using `create-pr` skill, optionally provide `pr-metadata.json`:

```json
{
  "branch_name": "feat/add-retry-logic-42",
  "pr_title": "[#42] feat: add retry logic",
  "pr_summary": "Add retry logic for transient API failures...",
  "intended_files": ["src/api/client.py", "tests/api/test_retry.py"]
}
```

---

## Workflow Triggers

### triage-issue.yml

**Triggers:**
- `issues: opened, reopened`
- `issue_comment: created` (non-bot comment)
- `workflow_dispatch` with `issue` input

**Inputs:**
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `issue` | yes (dispatch) | - | GitHub issue number |
| `agent_login` | no | `AGENT_LOGIN` var | Agent login for dispatch |
| `include_issue_body` | no | `true` | Include issue body markdown in output |

**Outputs:**
- `triage_result.json` - Triage classification and recommendations

### create-spec-from-issue.yml

**Trigger:** Issue labeled `ready-to-spec`

**Outputs:**
- `specs/issue-<N>/product.md`
- `specs/issue-<N>/tech.md`
- Spec PR created for human review

### plan-approved.yml

**Trigger:** Spec PR merged (issue gets `plan-approved` label)

**Behavior:**
- Checks implementation gates (no conflicts, dependencies satisfied)
- If gates pass → adds `ready-to-implement` label
- If gates fail → posts comment explaining blockers

### create-implementation-from-issue.yml

**Trigger:** Issue labeled `ready-to-implement`

**Outputs:**
- Implementation commits
- Implementation PR
- `implementation_summary.md`

### review-pr.yml

**Triggers:**
- `workflow_dispatch` with `pr_number` input
- `issue_comment: created` containing `@AGENT_LOGIN /review`

**Inputs:**
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `pr_number` | yes (dispatch) | - | Pull request number |

**Outputs:**
- `review.json` - Review verdict and comments
- GitHub PR review posted

### respond-to-pr-comment.yml

**Trigger:** PR comment containing `@AGENT_LOGIN` with command

**Commands:**
| Command | Purpose |
|---------|---------|
| `/explain` | Explain code changes in context |
| `/implement` | Implement requested change |
| `/review` | Request AI review of PR |
| `/fix` | Fix identified issues |
| `/approve` | Approve previous REQUEST_CHANGES |

**Outputs:**
- Implementation or explanation in comment thread

### update-pr-review.yml

**Trigger:** Human changes bot PR review (approve/request_changes)

**Behavior:**
- Analyzes human feedback
- Updates `review-pr-repo` companion skill guidance

### update-dedupe.yml

**Trigger:** Human closes issue as duplicate

**Behavior:**
- Analyzes duplicate closure
- Updates `dedupe-issue-repo` companion skill guidance

---

## JSON Schemas

### triage_result.json

Complete schema for triage workflow output:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "TriageResult",
  "type": "object",
  "required": ["labels", "repro", "confidence", "summary"],
  "properties": {
    "labels": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Labels from config.json that workflow should apply"
    },
    "repro": {
      "type": "string",
      "enum": ["high", "medium", "low", "unknown"],
      "description": "Reproducibility assessment"
    },
    "confidence": {
      "type": "string",
      "enum": ["high", "medium", "low"],
      "description": "Confidence in triage assessment"
    },
    "related_files": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Repository-relative file paths related to the issue"
    },
    "root_cause": {
      "type": "string",
      "description": "Evidence-based root cause assessment"
    },
    "summary": {
      "type": "string",
      "minLength": 1,
      "description": "Short triage conclusion"
    },
    "follow_up_questions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["question", "reasoning"],
        "properties": {
          "question": { "type": "string" },
          "reasoning": { "type": "string" }
        }
      },
      "description": "Questions for issue author (mutually exclusive with duplicate_of)"
    },
    "duplicate_of": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["issue_number", "title", "similarity_reason"],
        "properties": {
          "issue_number": { "type": "integer" },
          "title": { "type": "string" },
          "similarity_reason": { "type": "string" }
        }
      },
      "description": "Duplicate candidates (mutually exclusive with follow_up_questions)"
    },
    "issue_body": {
      "type": "string",
      "description": "Markdown summary for triage comment (when include_issue_body is true)"
    }
  },
  "additionalProperties": false
}
```

**Constraints:**
- `duplicate_of` and `follow_up_questions` are mutually exclusive
- If `duplicate_of` is non-empty, `follow_up_questions` must be `[]`
- If `duplicate_of` has 2+ candidates, include `duplicate` label (when available)
- Never include `plan-approved`, `ready-to-implement`, or `ready-to-spec` in `labels`

### review.json

Complete schema for PR review output:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ReviewResult",
  "type": "object",
  "required": ["verdict", "body"],
  "properties": {
    "verdict": {
      "type": "string",
      "enum": ["APPROVE", "REJECT", "COMMENT"],
      "description": "Review verdict"
    },
    "body": {
      "type": "string",
      "minLength": 1,
      "description": "Overall review summary"
    },
    "comments": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["path", "body"],
        "properties": {
          "path": {
            "type": "string",
            "description": "File path relative to repo root"
          },
          "line": {
            "type": "integer",
            "minimum": 1,
            "description": "Line number for inline comment"
          },
          "body": {
            "type": "string",
            "minLength": 1,
            "description": "Comment content"
          },
          "side": {
            "type": "string",
            "enum": ["LEFT", "RIGHT"],
            "default": "RIGHT",
            "description": "Side for multi-sided diff (LEFT=base, RIGHT=head)"
          }
        }
      },
      "description": "Inline comments on specific lines"
    },
    "recommended_reviewers": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 1,
      "description": "Recommended human reviewer login (at most one)"
    }
  },
  "additionalProperties": false
}
```

### pr-metadata.json

Schema for PR metadata when using `create-pr`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PRMetadata",
  "type": "object",
  "required": ["branch_name", "pr_title"],
  "properties": {
    "branch_name": {
      "type": "string",
      "pattern": "^[a-z]+/[a-z0-9-]+-[0-9]+$",
      "description": "Branch name following naming convention"
    },
    "pr_title": {
      "type": "string",
      "description": "PR title following title format"
    },
    "pr_summary": {
      "type": "string",
      "description": "Optional PR summary"
    },
    "intended_files": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Files intended to be included in this PR"
    }
  },
  "additionalProperties": false
}
```

### PR_DIFF_V1 Format

The `pr_diff.txt` format used by review workflows:

```
FILE <path>
LEFT <base_sha>
RIGHT <head_sha>
HUNK <start_line> <line_count>
<diff_content>
HUNK <start_line> <line_count>
<diff_content>
FILE <next_path>
...
```

**Structure:**
- `FILE` marks a file section with relative path
- `LEFT` and `RIGHT` mark base and head commit SHAs
- `HUNK` marks each diff hunk with start line and line count
- Content follows hunk header

---

## Best Practices

### When to Use Local Development Flow

Use local flow when:
- **Quick fixes** - Single developer, < 1 day work
- **Small features** - No team coordination needed
- **Personal experiments** - No spec required
- **Documentation updates** - Low-risk, self-contained

**Local flow benefits:**
- Fast iteration
- Full developer control
- No workflow overhead
- Immediate feedback

### When to Use GitHub Collaboration Flow

Use GitHub flow when:
- **Multi-developer collaboration** - Shared ownership
- **Complex features** - Need spec for alignment
- **Cross-module changes** - Coordination required
- **Production changes** - Review/approval needed
- **Changes affecting shared APIs** - Team visibility important

**GitHub flow benefits:**
- Team visibility
- Structured review process
- Spec-driven alignment
- Automated triage and review

### Decision Matrix

| Scenario | Recommended Flow | Reason |
|----------|------------------|--------|
| Fix typo in README | Local | Trivial, no coordination needed |
| Add logging to one module | Local | Self-contained, low risk |
| Refactor shared utility | GitHub | Affects multiple callers |
| New API endpoint | GitHub | Needs spec, review, docs |
| Performance optimization | GitHub | Needs benchmarking, review |
| Security fix | GitHub | Critical, needs thorough review |
| Test file additions | Local (with tests) | Self-contained |
| Multi-file refactor | GitHub | Coordination needed |

### Workflow Integration Tips

1. **Start with triage** - Let automation classify issues before manual work
2. **Spec early for complex features** - Specs prevent implementation drift
3. **Use local review before commit** - Run `$review-pr-local` on risky changes
4. **Keep specs updated** - Update specs as implementation evolves
5. **Respond to review comments promptly** - Use `/fix` or `/explain` commands
6. **Learn from bot reviews** - Human feedback improves companion skills

### Common Anti-Patterns

- **Skipping specs for complex features** - Leads to implementation drift
- **Broad staging** - Use `git add <specific-files>` only
- **Inventing issue IDs** - Never create branch with fake issue number
- **Force pushing without request** - Dangerous, avoid unless explicitly asked
- **Staging unrelated files** - Keep commits atomic
- **Ignoring reproducibility labels** - Use them to prioritize bug fixes

---

## Companion Skills Writing Guide

### Purpose of Repo-Local Companion Skills

Companion skills customize core workflow behavior for repository-specific needs:

- Override specific triage categories
- Customize review guidance
- Add project-specific logic
- Learn from human feedback

### Naming Convention

| Core Skill | Repo Companion |
|------------|----------------|
| `triage-issue` | `triage-issue-repo` |
| `review-pr` | `review-pr-repo` |
| `dedupe-issue` | `dedupe-issue-repo` |

**Location:** `.agents/skills/<skill-name>-repo/SKILL.md`

### Overridable Categories

#### triage-issue-repo

Only these categories can be specialized:

| Category | Customization Allowed |
|----------|----------------------|
| Area label inference | Map files/code patterns to `area:*` labels |
| Type label inference | Map issue content to `bug`/`enhancement`/`documentation` |
| Root cause suggestions | Project-specific common causes |
| Related file discovery | Project-specific file relationships |

**Cannot override:**
- Adding/removing protected labels (`ready-to-spec`, `ready-to-implement`, `plan-approved`)
- Duplicate detection logic
- Triage output schema

#### review-pr-repo

Only these categories can be specialized:

| Category | Customization Allowed |
|----------|----------------------|
| Code style rules | Project-specific style preferences |
| Architecture preferences | Module boundaries, ownership rules |
| Test coverage requirements | Project-specific coverage expectations |
| Common anti-patterns | Project-specific patterns to avoid |

**Cannot override:**
- Review verdict schema
- Comment format
- Security review requirements

### SKILL.md Template

```markdown
---
name: <skill-name>-repo
description: Repo-specific guidance for <skill-name> in this repository
---

# <skill-name>-repo

[Optional: brief description of what this skill customizes]

## Overridable Categories

[List the specific categories this skill overrides from the core skill]

## Repo-Specific Rules

### [Category 1: Area Label Inference]

[Custom logic for mapping files/code to area labels]

Examples:
- Files in `src/api/*` → suggest `area:workflow`
- Files in `.agents/skills/*` → suggest `area:skills`

### [Category 2: Root Cause Suggestions]

[Common root causes in this project]

Examples:
- API timeouts → check rate limiting configuration
- Null pointer errors → check input validation in handlers

### [Category 3: Code Style Rules]

[Project-specific style preferences]

Examples:
- Use `async/await` over callbacks
- Prefer type hints in Python functions
- Document public APIs with examples

## Integration

This skill is invoked by the core `<skill-name>` skill when:
- The core skill loads repo-specific guidance
- `.agents/skills/<skill-name>-repo/SKILL.md` exists
- The core skill reaches an overridable decision point

The core skill passes relevant context and expects this skill to:
- Return suggestions within allowed override categories
- Not modify outputs outside allowed categories
- Follow the same output schema as the core skill

## Examples

[Concrete examples of how this skill changes behavior]
```

### Implementation Checklist

- [ ] Create `.agents/skills/<name>-repo/SKILL.md`
- [ ] Document only overridable categories
- [ ] Test with sample issues/PRs
- [ ] Verify does not break core workflow
- [ ] Update companion skill from human feedback (via `update-*-repo` workflows)
- [ ] Document in `CLAUDE.md` or `AGENTS.md` if project-wide

### Common Patterns

#### Pattern 1: Area-Based File Mapping

```markdown
## Repo-Specific Rules

### Area Label Inference

Map file paths to area labels:
- `src/workflows/*.yml` → `area:workflow`
- `src/scripts/*.py` → `area:workflow`
- `.agents/skills/*/SKILL.md` → `area:skills`
- `specs/**/product.md` → `area:specs`
- `specs/**/tech.md` → `area:specs`
- `tests/**/*` → `area:tests`
```

#### Pattern 2: Custom Root Cause Templates

```markdown
## Repo-Specific Rules

### Root Cause Suggestions

For API-related issues:
- "Connection refused" → Check if service is running, verify port configuration
- "Timeout exceeded" → Check rate limiting, verify network connectivity
- "Unauthorized" → Check token validity, verify permission scopes

For workflow-related issues:
- "Workflow failed" → Check workflow syntax, verify action permissions
- "Action timeout" → Check step timeout settings, verify resource limits
```

#### Pattern 3: Project-Specific Terminology

```markdown
## Repo-Specific Rules

### Terminology Mapping

- "AICodingFlow" refers to this workflow system (not generic AI coding)
- "Spec-driven" means product.md + tech.md before implementation
- "Companion skill" means repo-local `-repo` skill variant
- "Protected labels" means workflow-gating labels (ready-to-spec, etc.)
```

### Testing Companion Skills

Test companion skills manually before committing:

```bash
# Test triage-issue-repo
python3 .github/scripts/prepare_issue_triage_context.py \
  --repo <repo> --issue <number> \
  --output triage_context.json

# Run OpenCode with both core and repo skill
# Inspect triage_result.json for expected behavior

# Test review-pr-repo
python3 .github/scripts/prepare_local_review_inputs.py

# Run OpenCode with both core and repo skill
# Inspect review.json for expected behavior
```

### Updating from Human Feedback

Companion skills auto-update through dedicated workflows:

| Workflow | Trigger | Update |
|----------|---------|--------|
| `update-pr-review.yml` | Human changes bot PR review | Updates `review-pr-repo` |
| `update-dedupe.yml` | Human closes issue as duplicate | Updates `dedupe-issue-repo` |

These workflows:
- Analyze human feedback patterns
- Generate skill update suggestions
- Commit updates to companion skill files

---

## Appendix: Quick Reference

### Branch Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation |
| `test` | Tests |
| `perf` | Performance |
| `chore` | Maintenance |
| `spec` | Spec-only changes |
| `impl` | Implementation from spec |

### Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Refactoring |
| `perf` | Performance |
| `docs` | Documentation |
| `test` | Tests |
| `build` | Build system |
| `ci` | CI/CD |
| `chore` | Maintenance |

### Protected Labels (Never Auto-Add)

- `ready-to-spec`
- `ready-to-implement`
- `plan-approved`

### PR Commands

| Command | Purpose |
|---------|---------|
| `/explain` | Explain code changes |
| `/implement` | Implement requested change |
| `/review` | Request AI review |
| `/fix` | Fix identified issues |
| `/approve` | Approve previous rejection |