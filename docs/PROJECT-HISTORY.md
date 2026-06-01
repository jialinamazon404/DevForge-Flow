# Project History

> 生成时间: 2026-06-01 02:42 UTC | 共 9 个 Spec

## Spec 列表

| Issue | 标题 | 状态 | 创建时间 | 文件 |
|-------|------|------|----------|------|
| #115 | 产品规格：本地 review base 选择与 CI 保持一致 | unknown | 2026-05-25 | [product.md](specs/issue-115/product.md) / [tech.md](specs/issue-115/tech.md) |
| #125 | Product Spec: `update-dedupe` 自进化 dedupe 规则 | unknown | 2026-05-25 | [product.md](specs/issue-125/product.md) / [tech.md](specs/issue-125/tech.md) |
| #18 | 产品规格：`create-implementation-from-issue` 自动实现 workflow | unknown | 2026-05-25 | [product.md](specs/issue-18/product.md) / [tech.md](specs/issue-18/tech.md) |
| #28 | 产品规格：增加 `respond-to-pr-comment` workflow | unknown | 2026-05-25 | [product.md](specs/issue-28/product.md) / [tech.md](specs/issue-28/tech.md) |
| #39 | 产品规格：`review-spec` 文档评审技能 | unknown | 2026-05-25 | [product.md](specs/issue-39/product.md) / [tech.md](specs/issue-39/tech.md) |
| #51 | 产品规格：PR review verdict 与 non-member gate 行为 | unknown | 2026-05-25 | [product.md](specs/issue-51/product.md) / [tech.md](specs/issue-51/tech.md) |
| #57 | 产品规格：plan-approved 同步 issue 生命周期状态 | unknown | 2026-05-25 | [product.md](specs/issue-57/product.md) / [tech.md](specs/issue-57/tech.md) |
| #77 | 产品规格：PR Bot `/review` 指令 | unknown | 2026-05-25 | [product.md](specs/issue-77/product.md) / [tech.md](specs/issue-77/tech.md) |
| #85 | 产品规格：允许本地 review 在有工作区改动时运行 | unknown | 2026-05-25 | [product.md](specs/issue-85/product.md) / [tech.md](specs/issue-85/tech.md) |

> 状态说明: `active` = 进行中 | `implemented` = 已实现 | `deprecated` = 已弃用 | `unknown` = 未标记

## 详情

### #115 — 产品规格：本地 review base 选择与 CI 保持一致

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #115
- **Product spec:** [`specs/issue-115/product.md`](specs/issue-115/product.md)
- **Tech spec:** [`specs/issue-115/tech.md`](specs/issue-115/tech.md)
- **摘要:** 本需求优化 `review-pr-local` 和 `review-spec-local` 的本地快照生成行为，使本地生成的 `pr_diff.txt` 尽量使用与 CI PR review 相同的 base SHA。目标是减少因为本地 remote stale 或默认 base 顺序不合适导致的 diff 噪声，让本地 review 更接近 GitHub Actions 中真实 PR review 的输入。

### #125 — Product Spec: `update-dedupe` 自进化 dedupe 规则

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #125
- **Product spec:** [`specs/issue-125/product.md`](specs/issue-125/product.md)
- **Tech spec:** [`specs/issue-125/tech.md`](specs/issue-125/tech.md)
- **摘要:** 新增一个 `update-dedupe` 自我改进流程，用于从维护者近期正式关闭为 duplicate 的 issue 中学习稳定重复模式，并把这些模式沉淀到 repo-local dedupe companion guidance。该流程不处理单个新 issue，也不直接改变 `dedupe-issue` 的核心判重合同；它只在证据足够强时，为后续 `dedupe-issue` 运行提供更容易识别的 known-duplicate clusters。

### #18 — 产品规格：`create-implementation-from-issue` 自动实现 workflow

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #18
- **Product spec:** [`specs/issue-18/product.md`](specs/issue-18/product.md)
- **Tech spec:** [`specs/issue-18/tech.md`](specs/issue-18/tech.md)
- **摘要:** 新增一个 GitHub Actions workflow，用于把已经准备实现的 GitHub issue 交给 Codex agent 自动产出实现分支，并由外层 workflow 创建或更新 implementation PR。该 workflow 面向已经完成 triage/spec 阶段的 issue，只有在明确满足 `ready-to-implement` 和 bot assignment 等 issue 条件时才会启动实现；approved spec PR 只用于选择实现上下文。

### #28 — 产品规格：增加 `respond-to-pr-comment` workflow

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #28
- **Product spec:** [`specs/issue-28/product.md`](specs/issue-28/product.md)
- **Tech spec:** [`specs/issue-28/tech.md`](specs/issue-28/tech.md)
- **摘要:** 新增一个 GitHub Actions workflow，用于响应 PR 中的显式 `@bot /fix` 评论，让 Codex agent 在当前 PR 上产出修复 diff，并由外层 workflow 提交、推送、更新 PR 或创建 follow-up PR。该 workflow 面向 PR conversation comment、inline review comment、以及 PR review body，不是 issue 的 `ready-to-spec` 或 `ready-to-implement` 流程。

### #39 — 产品规格：`review-spec` 文档评审技能

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #39
- **Product spec:** [`specs/issue-39/product.md`](specs/issue-39/product.md)
- **Tech spec:** [`specs/issue-39/tech.md`](specs/issue-39/tech.md)
- **摘要:** 新增一个核心 Codex 技能 `review-spec`，专门用于评审 `specs/` 目录下的文档型 PR。该技能应复用 `review-pr` 的离线快照输入与 `review.json` 输出契约，但评审重点从代码缺陷转为规格文档质量，包括完整性、清晰性、可行性、对齐度和一致性。

### #51 — 产品规格：PR review verdict 与 non-member gate 行为

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #51
- **Product spec:** [`specs/issue-51/product.md`](specs/issue-51/product.md)
- **Tech spec:** [`specs/issue-51/tech.md`](specs/issue-51/tech.md)
- **摘要:** 本功能让 `review-pr` / `review-spec` 产生的机器评审结果不仅能发布为普通 GitHub review comment，还能在特定高风险场景下转换为真正的 GitHub blocking review event。目标是让 Bot 的判断、GitHub 上展示的 review event、以及是否请求人工 reviewer 之间有清晰、可验证、一致的规则。

### #57 — 产品规格：plan-approved 同步 issue 生命周期状态

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #57
- **Product spec:** [`specs/issue-57/product.md`](specs/issue-57/product.md)
- **Tech spec:** [`specs/issue-57/tech.md`](specs/issue-57/tech.md)
- **摘要:** 本功能完善 spec-first GitHub Actions 生命周期：当维护者在 spec PR 上添加 `plan-approved` 后，系统应自动把 linked issue 从“需要写 spec”的状态推进出来，移除 issue 上的 `ready-to-spec`。如果 linked issue 已经同时满足实现启动条件，即带有 `ready-to-implement` 且已分配给配置的 bot，则系统应在完成状态同步后自动触发 `create-implementation-from-issue`。

### #77 — 产品规格：PR Bot `/review` 指令

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #77
- **Product spec:** [`specs/issue-77/product.md`](specs/issue-77/product.md)
- **Tech spec:** [`specs/issue-77/tech.md`](specs/issue-77/tech.md)
- **摘要:** 本功能为 PR 下的 Bot 增加 `/review` 指令，让维护者可以在 PR body-level comment 中通过 `@AGENT_LOGIN /review` 显式重新触发现有 `review-pr` / `review-spec` workflow。目标是把“重新运行 AI PR Review”从单纯 mention Bot 或手动 workflow dispatch，收敛成一个清晰、可审计、可测试的 PR Bot 评论命令。

### #85 — 产品规格：允许本地 review 在有工作区改动时运行

- **状态:** unknown
- **创建时间:** 2026-05-25
- **Issue:** #85
- **Product spec:** [`specs/issue-85/product.md`](specs/issue-85/product.md)
- **Tech spec:** [`specs/issue-85/tech.md`](specs/issue-85/tech.md)
- **摘要:** `review-pr-local` 和 `review-spec-local` 是开发者在本地提交前运行 AI review 的入口。当前本地 review 准备阶段要求整个 Git working tree 必须干净，否则直接中止。这和 issue 中描述的常见开发流程冲突：开发者通常希望先完成本地修改、运行 review、根据 review 调整，再把最终结果整理成 commit。

