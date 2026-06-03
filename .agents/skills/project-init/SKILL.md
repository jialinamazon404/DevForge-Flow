---
name: project-init
description: Understand a project's history, architecture, and current state by analyzing its structure, tech stack, git history, specs, and workflows. Use when the user says "understand this project", "init this project", "what is this project about", or when an AI agent first encounters a new repository and needs project context.
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

### Step 5: Detect conventions

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

### Step 6: Generate project brief

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

### Step 7: Update agent context

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