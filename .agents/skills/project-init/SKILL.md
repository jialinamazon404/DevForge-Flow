---
name: project-init
description: Understand a project's history, architecture, and current state by analyzing its structure, tech stack, git history, specs, and workflows. When no specs exist in the specs/ directory, automatically initialize a baseline spec by chaining create-issue, create-product-spec, and create-tech-spec skills. When non-standard specs exist outside the AICodingFlow ecosystem (e.g., SPEC.md, ARCHITECTURE.md, docs/), offer to migrate them into specs/issue-N/product.md + tech.md format or create fresh baseline specs alongside them. Use when the user says "understand this project", "init this project", "what is this project about", or when an AI agent first encounters a new repository and needs project context.
---

# project-init

Analyze and understand a project's history, architecture, and current state.

## When to use

Use this skill when:

- An AI agent first encounters a new repository and needs project context
- The user says "understand this project", "init this project", "what is this project about"
- The user wants a quick overview of project history before starting work
- A new team member needs to understand the project landscape
- Before making changes, to ensure alignment with project conventions

Do not use this skill for implementation, triage, or review — those use
`implement-specs`, `triage-issue`, `review-pr` respectively.

## Workflow

### Step 1: Detect project basics

Check the project root and gather basic information:

```bash
git rev-parse --show-toplevel
```

Scan for project identity files and extract:

| File | Extract |
|------|---------|
| `package.json` | name, description, dependencies, scripts, tech stack |
| `pyproject.toml` | name, Python version, dependencies |
| `go.mod` | module name, Go version |
| `Cargo.toml` | name, Rust edition, dependencies |
| `pom.xml` / `build.gradle` | Java/Kotlin project info |
| `README.md` | project description, purpose |
| `.github/workflows/*.yml` | CI/CD pipeline summary |
| `specs/issue-*/product.md` | feature history and status |

### Step 2: Analyze git history

```bash
# Recent activity
git log --oneline -20

# Branch structure
git branch -r --sort=-committerdate | head -10

# Contributors
git shortlog -sn --all | head -10

# Project age and commit count
git rev-list --count HEAD
git log --format="%ci" --reverse | head -1
```

Summarize:
- Project age and total commits
- Recent activity (last 20 commits themes)
- Active branches and their purpose
- Key contributors

### Step 3: Understand project structure

```bash
# Top-level directory layout
ls -1

# Key directories depth
find . -maxdepth 2 -type d | grep -v node_modules | grep -v .git | sort
```

Build a structural map:
- Source code directories and their purpose
- Test directories
- Config files
- Documentation
- Workflow files (.github/workflows/)

### Step 4: Check AICodingFlow integration

If the project has AICodingFlow installed (check for `.agents/AGENTS.md`):

```bash
# Specs status
rg "status:" specs/issue-*/product.md specs/issue-*/tech.md

# Available workflows
ls .github/workflows/

# Skills available
ls .agents/skills/
```

Summarize:
- Installed mode: full (all workflows) or lite (non-AI only)
- Spec history: how many specs, their status (active/implemented/deprecated)
- Available skills and their categories
- Whether AGENT_API_KEY appears configured (check workflow env references)

### Step 5: Evaluate and initialize spec structure

Determine the project's current spec situation by checking three
layers:

#### 5.1 Check for ecosystem-compliant specs

```bash
ls -d specs/issue-*/ 2>/dev/null | wc -l
```

If the count is greater than zero, the project already has
AICodingFlow-compliant specs (`product.md` + `tech.md` pairs).
Skip initialization and proceed to Step 6.

#### 5.2 Scan for non-standard spec files

If no `specs/issue-*/` directories exist, scan for other
documentation that looks like specs — files outside our ecosystem
that describe behavior, architecture, or design decisions:

```bash
# Common non-standard spec locations
for f in SPEC.md DESIGN.md ARCHITECTURE.md ROADMAP.md; do
  [ -f "$f" ] && printf '%s\n' "$f"
done

# Directories that may contain spec-like docs
for d in docs specs design specifications arch; do
  [ -d "$d" ] && printf '%s/\n' "$d"
done

# Any markdown files with spec-like titles
rg -l -i "(specification|architecture|design doc|system design|api spec|feature spec)" *.md docs/*.md 2>/dev/null
```

For each candidate file or directory found, read enough to determine:
- Is it a **product-level** doc (describes behavior, user experience, requirements)?
- Is it a **tech-level** doc (describes architecture, implementation, data flow)?
- Is it just general documentation (README, changelog, contributing guide — not a spec)?

Classify what you find:

| Classification | Examples | Action |
|---------------|----------|--------|
| Product-level spec | `docs/FEATURE-X.md`, `SPEC.md` with behavior descriptions | Migrate to `product.md` |
| Tech-level spec | `ARCHITECTURE.md`, `design/SYSTEM-DESIGN.md` | Migrate to `tech.md` |
| Mixed spec | Single file covering both behavior + architecture | Split into `product.md` + `tech.md` |
| General docs | README, CHANGELOG, CONTRIBUTING | Leave in place, reference in brief |

#### 5.3 Decide on spec initialization

Based on the scan results, present the situation to the user:

**Scenario A — No specs at all**

> "No specs found in this project. Would you like me to create an
> initial project-overview spec (product + tech) so the project has
> a documented baseline?"

If the user confirms, proceed to sub-steps 5a–5c below.

**Scenario B — Non-standard specs exist**

> "I found existing spec-like docs outside the AICodingFlow ecosystem:
> - `<list of files with classification>`
>
> These are not in the `specs/issue-N/product.md` + `tech.md` format.
> Would you like me to:
> 1. **Migrate** — Convert these docs into AICodingFlow-compliant specs
>    (preserves existing content, restructures into product.md + tech.md)
> 2. **Initialize fresh** — Create a new baseline spec alongside existing docs
>    (keeps old docs untouched, adds ecosystem-compliant specs)
> 3. **Skip** — Leave existing docs as-is, just note them in the project brief"

If the user chooses option 1 (Migrate), proceed to sub-steps 5a–5c
but incorporate content from the non-standard specs into the new
`product.md` and `tech.md`. Read each source file, extract relevant
sections, and fold them into the appropriate ecosystem spec.

If the user chooses option 2 (Initialize fresh), proceed to sub-steps
5a–5c without referencing the non-standard specs. The new baseline
spec captures current state independently.

If the user chooses option 3 (Skip), skip to Step 6 and note
the non-standard spec locations in the project brief.

**Scenario C — Ecosystem-compliant specs exist**

Already handled in 5.1: skip to Step 6.

#### 5a. Create a project-overview issue

Use the **`create-issue`** skill to open a GitHub issue titled:

`Project Overview and Baseline Documentation`

The issue body should include:
- A brief description of the project (from Step 1 detection)
- The project brief summary (from Step 7, if already generated)
- A request to document the current state as a baseline spec
- If migrating non-standard specs: list the source files being converted
- Label: `documentation` (if the repo supports it)

After the issue is created, note the issue number (e.g., `#N`).

#### 5b. Create the product spec

Use the **`create-product-spec`** skill to generate
`specs/issue-N/product.md`.

Construct `issue_context.json` from the project brief and the
GitHub issue created in 5a:

```json
{
  "issue_number": N,
  "title": "Project Overview and Baseline Documentation",
  "description": "<project brief summary from Step 7>",
  "labels": [],
  "assignees": [],
  "product_spec": "specs/issue-N/product.md",
  "tech_spec": "specs/issue-N/tech.md",
  "target_branch": "main"
}
```

The product spec should document the project's **current behavior**:
- Summary of what the project does today
- Current user-facing features and workflows
- Known limitations and edge cases
- Success criteria (what "working correctly" means for the current state)
- Open questions about ambiguous or undocumented behavior

**If migrating non-standard specs**: Read each product-level source
file identified in 5.2. Extract behavior descriptions, user
requirements, and feature specs. Fold them into the `product.md`
sections. Add a `## Source Documents` section at the end listing
the original file paths with a note like:
> "Content migrated from `<original-file-path>`. Original file should
> be archived or removed after review."

This is a *baseline snapshot*, not a feature proposal. Focus on
what exists, not what should be built next.

#### 5c. Create the tech spec

Use the **`create-tech-spec`** skill to generate
`specs/issue-N/tech.md`.

The tech spec should document the project's **current architecture**:
- Problem the current implementation solves
- Relevant code: key files, modules, data flows
- Current state of the codebase (structure, patterns, conventions)
- End-to-end flow of the primary user journey
- Known risks, gaps, and areas with no test coverage
- Testing and validation approach currently in use
- Follow-ups: areas that need deeper documentation later

**If migrating non-standard specs**: Read each tech-level source
file identified in 5.2. Extract architecture descriptions, data
flow diagrams, system design decisions, and implementation notes.
Fold them into the `tech.md` sections. Add a `## Source Documents`
section at the end listing the original file paths.

This is a *baseline architecture snapshot*, not an implementation
plan for new features.

#### Skip conditions

Do **not** initialize specs if:
- The `specs/` directory already has ecosystem-compliant specs
  (`specs/issue-*/product.md` pairs)
- The user declines all offers (Scenario A decline, or Scenario B option 3)
- The project has no git remote (no GitHub repo to create an issue on)
- The `gh` CLI is unavailable or unauthenticated

In these cases, skip to Step 6. Note in the project brief:
- Whether baseline ecosystem specs exist or not
- Where non-standard spec files live (if any)
- Whether migration was offered but declined

### Step 6: Detect conventions

Check for convention files:

| File | What to check |
|------|---------------|
| `.editorconfig` | Coding style rules |
| `conventions.md` / `docs/conventions.md` | Project conventions |
| `.agents/AGENTS.md` | Agent behavior rules |
| `CLAUDE.md` | Claude-specific rules |
| `.claude/` | Claude Code configuration |
| `.cursor/rules/` | Cursor rules |
| `.github/CODEOWNERS` | Code ownership |
| `.github/issue-triage/config.json` | Issue triage labels |

Summarize key conventions: commit format, branch naming, label system, review expectations.

### Step 7: Generate project brief

Compile all findings into a structured project brief:

```markdown
# Project Brief: <project-name>

## Identity
- **Name**: <name>
- **Description**: <one-line from README or package.json>
- **Age**: <X months/years, Y total commits>
- **Primary language**: <detected language/framework>

## Architecture
- **Tech stack**: <frameworks, languages, key dependencies>
- **Structure**: <key directories and their roles>
- **CI/CD**: <workflows summary>

## History
- **Recent activity**: <last 2-4 weeks themes>
- **Active branches**: <list with purpose>
- **Spec history**: <X specs total: Y active, Z implemented, W deprecated>

## AICodingFlow Integration
- **Mode**: full / lite
- **Skills**: <count and key skills>
- **Workflows**: <installed workflow count and names>

## Conventions
- **Commits**: <format, e.g. "SNXXX: type(scope): message">
- **Branches**: <format, e.g. "type/desc-issueID">
- **Labels**: <key label categories>
- **Review**: <expectations, e.g. "AI review + human approval">

## Getting Started
- **Install**: <command>
- **Test**: <command>
- **Build**: <command>
- **Key entry points**: <main files/directories>
```

### Step 8: Update agent context

If the project has `.agents/AGENTS.md`, append or update a
`## Project Context` section with the brief summary, so future
sessions can reference it without re-running full analysis.

If no `.agents/AGENTS.md` exists, create it with the project brief
as the initial content.

## Output format

Present the project brief to the user in markdown format.
Ask the user to confirm or correct any inaccuracies before
saving to `.agents/AGENTS.md`.

### If project has no git history

When the directory is not a git repository or has no commits:

- Report that this appears to be a new or untracked project
- Still analyze the file structure and any config files
- Suggest initializing git if appropriate
- Generate a lighter brief focused on file structure

### If project is very small

For projects with fewer than 10 files:

- Provide a concise brief without the full structure
- Focus on what exists and what might be needed
- Suggest relevant AICodingFlow skills to add

## Limitations

- Git history analysis is limited to what's available locally.
  For remote-only branches, use `gh api` or `git ls-remote`.
- Spec status requires YAML frontmatter in spec files.
  Legacy specs without frontmatter show as "unknown".
- Does not read inside source files for deep architectural
  analysis — that's a separate deep-read step the user can
  request after this init.
- Spec initialization requires GitHub CLI (`gh`) and a remote
  repository. Projects without GitHub connectivity cannot
  auto-create issues and specs; the agent should note this
  in the brief and suggest manual spec creation.
- The baseline spec is a snapshot of current state. It does not
  replace feature-specific specs that should be created when
  new issues arise.