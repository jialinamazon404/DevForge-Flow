---
name: validate-issue
description: Validate issue or requirement input quality by letting the user select the input type (bug, simple-feature, PRD, epic, vague), then running type-specific elemental and logical gate checks. Produces structured validation results with known gaps and routing suggestions.
---

# Validate issue input quality

Let the user select an input type (bug, simple-feature, PRD, epic, or vague),
then run type-specific elemental and logical gate checks, and produce a
structured validation result with known gaps and downstream routing suggestions.

## When to use

This skill is called by `$create-issue` before building title and body, or
called standalone when a user wants to check input quality before submission.

## Inputs

Expect the prompt to include:

- the user's raw input text (issue description, requirement, or PRD)
- context from the current conversation (clarifications, answers to questions)
- optionally: the target repository and issue template metadata from `$create-issue`

## Workflow

### 1. Select Input Type

Present the five input types to the user and ask them to select one:

1. **Bug** — Something is broken: error, crash, regression, unexpected behavior
2. **Simple Feature** — A single new capability: UX improvement, small behavior change
3. **PRD** — A substantial requirement: multi-module, business process, user stories + metrics
4. **Epic** — A strategic initiative: cross-team, multiple deliverables, roadmap item
5. **Vague** — I'm not sure yet, need help clarifying

Ask: "Which type best describes your input? (1-5, or type the name)"

After the user selects:
- **If the selection matches the content** — accept it and proceed to step 2.
- **If the selection seems mismatched** (e.g., user says "bug" but describes a new
  feature, or says "simple-feature" but the scope spans multiple modules) — suggest
  a correction with a brief reason: "Your input describes a new capability rather
  than a broken behavior. Would 'simple-feature' (2) be more appropriate?" Accept
  the user's final choice regardless.
- **If the user selects "vague" (5)** — ask 2-3 clarification questions:
  - "What is the core problem or capability you need?"
  - "Who is affected by this — end users, developers, or another group?"
  - "Is this a bug (something broken) or a new capability (something missing)?"
  Re-classify after the user responds. If still unclear after one round, use the
  user's best guess and proceed with a minimal gate.

**The selected type determines the gate rules applied in steps 2 and 3.**

### 2. Elemental Gate — Structural Completeness

Check that each required element is **present and substantive** (not empty,
not "Not provided", not a placeholder). For each missing element, generate a
targeted prompt question.

#### Bug elemental items

| Element | Check | Prompt question when missing |
|---------|-------|------------------------------|
| affected_user | Who experiences this? | "Who is affected by this bug? (end users, internal team, specific role)" |
| problem_statement | What went wrong? | "What is the observed incorrect behavior?" |
| expected_vs_actual | Expected vs observed | "What did you expect to happen, and what actually happened?" |
| repro_steps | How to reproduce | "What are the steps to reproduce this issue?" |

#### Simple-feature elemental items

| Element | Check | Prompt question when missing |
|---------|-------|------------------------------|
| affected_user | Who benefits? | "Who will benefit from this feature? (end users, developers, specific role)" |
| acceptance_criteria | What defines "done"? | "What are the acceptance criteria — what behavior must be true for this feature to be considered complete?" |
| scope_boundary | What's in/out? | "What is explicitly out of scope for this feature? (helps prevent scope creep)" |

#### PRD elemental items (10 items)

| Element | Check | Prompt question when missing |
|---------|-------|------------------------------|
| business_context | Why does this matter to the business? | "What business need or strategic goal drives this requirement?" |
| target_users | Who are the primary users? | "Who are the target user personas or roles? What are their current pain points?" |
| business_flow | End-to-end business process steps | "Describe the business flow: what triggers it, what steps happen, what roles are involved, and what is the end state?" |
| data_flow | Data lifecycle (input → processing → storage → output) | "Describe the data flow: what data enters the system, how is it transformed, where is it stored, and what is the output?" |
| feature_modules | Decomposed subsystems | "What are the main feature modules or subsystems? How do they interact?" |
| acceptance_criteria | What defines "done"? | "What are the acceptance criteria — specific, testable conditions that must be true for this requirement to be considered complete?" |
| success_metrics | KPIs and measurable outcomes | "What success metrics or KPIs will indicate this requirement has delivered its intended value?" |
| boundary_error_handling | Edge cases, error scenarios | "What boundary conditions and error scenarios need handling? (e.g., empty data, timeouts, concurrent access, permission failures)" |
| scope_boundary | What's in/out of scope | "What is explicitly in scope and out of scope for this requirement?" |
| dependencies | External dependencies and constraints | "What external systems, APIs, teams, or resources does this requirement depend on?" |

#### Epic elemental items

| Element | Check | Prompt question when missing |
|---------|-------|------------------------------|
| business_goal | Strategic objective | "What strategic goal or business objective does this epic serve?" |
| target_audience | Who benefits across deliverables | "Who is the target audience across all deliverables in this epic?" |
| strategic_rationale | Why now? | "Why is this epic important now? What would happen if we delayed it?" |
| dependency_map | Cross-team or cross-system dependencies | "What teams, systems, or external dependencies must be coordinated for this epic?" |

**Process**:
- Ask targeted questions for ALL missing elements at once (single round).
- After the user responds, re-check only the previously missing items.
- Items still missing after one round are marked as **skipped** — the user chose
  not to provide them, and they become known gaps.
- Never block submission. Never ask more than one round of questions.

### 3. Logical Gate — Content Quality

Only run logical checks for items that passed the elemental gate. An element
that was **skipped** in step 2 makes its corresponding logical check
**unverifiable** (not failed, not passed — marked as `skip`).

#### Bug logical checks

| Check | Validates | Failure question |
|-------|-----------|-----------------|
| clarity | Is the problem description unambiguous? | "The problem statement is ambiguous — could you rephrase it more precisely?" |
| reproducibility | Are repro steps specific enough to follow? | "The repro steps are too vague — can you provide more specific steps, including any necessary preconditions?" |

#### Simple-feature logical checks

| Check | Validates | Failure question |
|-------|-----------|-----------------|
| testability | Are acceptance criteria specific and verifiable? | "The acceptance criteria are too broad — can you make them more specific and testable? (e.g., 'user can export CSV' rather than 'user can export data')" |
| scope_feasibility | Is the scope realistic for a single deliverable? | "The scope seems broad for a single feature — would you like to narrow it or split into multiple issues?" |

#### PRD logical checks (8 checks)

| Check | Validates | Depends on elemental | Failure question |
|-------|-----------|---------------------|-----------------|
| problem_solution_fit | Does the solution address the stated business context? | business_context | "The proposed solution doesn't clearly address the business context — how does each feature module solve the stated problem?" |
| business_flow_completeness | Does the flow cover trigger → steps → end state with roles? | business_flow | "The business flow is incomplete — are there missing steps, unclear role assignments, or undefined end states?" |
| data_flow_closure | Does data have clear input, processing, storage, and output? No data "dead ends"? | data_flow | "The data flow has gaps — is data entering without a defined output, or is there processing without a defined input source?" |
| module_consistency | Do feature modules have consistent interfaces and no overlapping responsibilities? | feature_modules | "Some feature modules seem to overlap in responsibility or have inconsistent interfaces — can you clarify the boundaries between modules?" |
| metrics_alignment | Do success metrics map to specific feature modules? | success_metrics + feature_modules | "Some success metrics don't map to any feature module — which module delivers each metric?" |
| exception_coverage | Do error handling scenarios cover the most likely failure modes? | boundary_error_handling | "The error handling doesn't cover likely failure modes — what happens when [specific edge case] occurs?" |
| feasibility | Is the requirement implementable with current tech and resources? | dependencies + scope_boundary | "Given the dependencies and scope, is this feasible within the current technical and resource constraints?" |
| risk_identification | Are major risks (technical, organizational, timeline) acknowledged? | scope_boundary + dependencies | "What are the biggest risks for this requirement — technical unknowns, dependency delays, or scope expansion?" |

#### Epic logical checks

| Check | Validates | Failure question |
|-------|-----------|-----------------|
| scope_feasibility | Is the epic scoped enough to plan deliverables? | "The epic scope is too broad to plan concrete deliverables — can you identify the minimum viable subset?" |
| dependency_mapping | Are cross-team dependencies identified with timelines? | "Some dependencies lack timeline expectations — when do you need each dependency ready?" |
| risk_assessment | Are major strategic and execution risks identified? | "What are the biggest strategic and execution risks for this epic?" |

**Process**:
- Ask targeted questions for ALL failed checks at once (single round).
- After the user responds, re-check only the previously failed items.
- Checks still failing after one round are marked as **known_gap**.
- Checks that depend on **skipped** elemental items are marked as **skip**
  (unverifiable, not counted as failure).
- Never block submission. Never ask more than one round of questions.

### 4. Produce Validation Result

After both gates complete, produce a structured result:

**Classification**: the determined input type (bug, simple-feature, prd, epic, vague)

**Elemental results**: for each element, one of:
- `pass` — present and substantive
- `skip` — missing after one round of questions, user chose not to provide
- `fail` — present but empty/placeholder (treated as missing in next round)

**Logical results**: for each check, one of:
- `pass` — content quality satisfied
- `skip` — unverifiable because the corresponding elemental item was skipped
- `fail` — content quality issue identified
- `known_gap` — still failing after one round of questions

**Known gaps**: list of (item/check, reason) for all `skip` and `known_gap` entries.

**Routing suggestion**:

| Type | Suggested next step |
|------|--------------------|
| bug | Issue created → `$triage-issue` will auto-run after creation |
| simple-feature | Issue created → optionally `$write-product-spec` or `$spec-driven-implementation` for spec flow |
| prd | Tracking issue + `$spec-driven-implementation` for full spec pipeline (product spec → tech spec → implementation issues) |
| epic | Tracking issue + `$epic-breakdown-advisor` first, then `$spec-driven-implementation` for each sub-feature |
| vague | Issue created with "Quality Gaps" section → `$triage-issue` will request clarification |

### 5. Format Result for Issue Body

When called from `$create-issue`, format the validation result into two parts
for inclusion in the GitHub issue body:

**Part 1 — Machine-readable block** (HTML comment, invisible to users but
parseable by downstream skills like `$triage-issue`):

```markdown
<!-- validate-issue-result
classification: <type>
elemental: {<item>: <pass|skip|fail>, ...}
logical: {<check>: <pass|skip|fail|known_gap>, ...}
known_gaps: [<item>: <reason>, ...]
routing: <suggested_skill>
-->
```

**Part 2 — Human-readable section** (only included when known gaps exist):

```markdown
## Quality Gaps

The following gaps were identified during input validation:

- **<Gap Item>**: <reason — what was missing and why it matters>
```

Each gap entry should explain:
- what was missing or unclear
- why it matters for downstream spec creation or implementation
- a brief suggestion for how to address it (optional, one sentence)

When ALL items pass both gates (no known gaps), do NOT include the "Quality
Gaps" section — the issue body stays clean.

## Rules

- **Max 1 question round per gate** — ask all missing/failing items at once,
  then re-check only those items. Never loop more than once.
- **Never fully block** — the user can always proceed with known gaps documented
  in the issue body. Forced submission with gaps is explicitly allowed.
- **Elemental gate must complete before logical gate** — logical checks that
  depend on skipped elemental items are unverifiable (skip), not failed.
- **Type-specific rules** — the user selects the type first (step 1), then only
  the gate rules for that type are applied. If the selection seems mismatched,
  suggest a correction but accept the user's final choice. Never apply PRD
  checks to a bug report.
- **Targeted questions** — each question must be specific to the missing item,
  not generic boilerplate like "please provide more details".
- **No side effects** — this skill never creates issues, labels, comments, or
  any GitHub mutations. It only produces a validation result for the calling
  skill to use.