# DevForge-Flow 规范文档

本文档定义了 DevForge-Flow (AICodingFlow) 的所有规范、Schema 和最佳实践。它是开发者和 AI Agent 在此工作流系统中工作的权威参考。

## 目录

- [Git 规范](#git-规范)
- [标签系统](#标签系统)
- [Spec 规范](#spec-规范)
- [PR 规范](#pr-规范)
- [工作流触发器](#工作流触发器)
- [JSON Schema](#json-schema)
- [最佳实践](#最佳实践)
- [技能包编写指南](#技能包编写指南)

---

## Git 规范

### 分支命名

**格式:** `<type>/<short-desc>-<issueID>`

| 类型 | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能或能力 | `feat/add-retry-logic-42` |
| `fix` | Bug 修复 | `fix/handle-null-input-15` |
| `refactor` | 不改变行为的代码重构 | `refactor/simplify-auth-module-33` |
| `docs` | 文档变更 | `docs/update-readme-7` |
| `test` | 添加或更新测试 | `test/add-unit-tests-21` |
| `perf` | 性能优化 | `perf/optimize-query-55` |
| `chore` | 维护任务 | `chore/update-dependencies-12` |
| `spec` | 仅 Spec 变更（无代码） | `spec/define-api-structure-99` |
| `impl` | 从 Spec 实现 | `impl/add-auth-flow-99` |

**规则:**
- 关联 Issue 的分支必须包含 Issue ID 后缀
- 无 Issue 分支使用 `<type>/<user-provided-name>`（禁止伪造 Issue ID）
- 描述必须是简短的英文小写单词，用连字符分隔
- 移除标点、填充词、重复分隔符和非分支字符

**验证:**
```bash
git check-ref-format --branch <branch-name>
```

### 提交格式

**格式:** Conventional Commits + 需求编号前缀

```text
SNXXX: type(scope): summary

[可选正文]

Refs #<issueID>
```

**需求编号 (SNXXX):**
- 外部需求追踪编号（如 `SN001`, `SN123`, `SN999`）
- 必须位于提交消息开头
- 无需校验 — 只需与外部需求系统匹配
- 格式: `SN` + 3位数字

**类型:** `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `build`, `ci`, `chore`

**Issue 关联:**
- 仅在提交确定关闭 Issue 时使用 `Fixes #123`
- 对于部分完成、准备工作、纯文档或清理工作使用 `Refs #123`
- 禁止伪造 Issue ID

**示例:**

```text
SN001: feat(auth): add OAuth2 support

Refs #42

SN002: fix(api): handle null response from upstream service

Fixes #15

SN003: docs(conventions): document branch naming rules

Refs #7
```

**避免:** 使用 `update`, `changes`, `misc`, `wip` 作为提交类型

---

## 标签系统

### 保护标签

这些标签控制关键工作流转换，不能被 Triage 自动化自动添加或移除：

| 标签 | 颜色 | 用途 |
|------|------|------|
| `ready-to-spec` | `#1D76DB` | Issue 已准备好创建 Spec |
| `ready-to-implement` | `#0E8A16` | Spec 已批准，准备好实现 |
| `plan-approved` | `#5319E7` | 实现计划已批准 |

**规则:**
- Triage 工作流绝不能在 `labels` 输出中包含这些标签
- 只有人工审核/批准可以添加或移除这些标签
- 这些标签控制 Spec 到实现的转换关口

### 流程标签

| 标签 | 颜色 | 用途 |
|------|------|------|
| `triaged` | `#C2E0C6` | Issue 已被审核和分类 |
| `needs-info` | `#D876E3` | 需要更多信息才能推进 |
| `duplicate` | `#CFD3D7` | Issue 已被识别为重复 |
| `ready-for-review` | - | PR 已准备好人工审核 |

### 可复现性标签

| 标签 | 颜色 | 用途 |
|------|------|------|
| `repro:high` | `#B60205` | 高置信度或容易复现 |
| `repro:medium` | `#FBCA04` | 中等置信度或部分可复现 |
| `repro:low` | `#C5DEF5` | 低置信度或难以复现 |
| `repro:unknown` | `#CFD3D7` | 信息不足无法估计 |

### 区域标签

| 标签 | 额色 | 用途 |
|------|------|------|
| `area:workflow` | `#7057FF` | GitHub 工作流和 Python 自动化脚本 |
| `area:skills` | `#D4C5F9` | Codex Skills 和 Agent 行为指导 |
| `area:specs` | `#0075CA` | Product Spec、Tech Spec 和 Spec 驱动工作流 |
| `area:tests` | `#BFDADC` | 自动化测试和测试 fixtures |

### 类型标签

| 标签 | 颜色 | 用途 |
|------|------|------|
| `bug` | `#D73A4A` | 某些功能未按预期工作 |
| `enhancement` | `#A2EEEF` | 新能力或改进请求 |
| `documentation` | `#0075CA` | 文档或指导更新 |
| `question` | `#D876E3` | Issue 主要是问题或讨论 |
| `invalid` | `#E4E669` | Issue 未描述有效任务 |
| `wontfix` | `#FFFFFF` | Issue 不会被处理 |

### 辅助标签

| 标签 | 颜色 | 用途 |
|------|------|------|
| `good first issue` | `#7057FF` | Issue 适合首次贡献 |
| `help wanted` | `#008672` | 需要维护者额外关注 |

---

## Spec 规范

### 目录结构

```
specs/
├── issue-<N>/          # Issue #N 的 Specs
│   ├── product.md      # Product Spec（行为、UX、验证）
│   └── tech.md         # Tech Spec（架构、实现）
└── ...
```

### Product Spec 章节

每个 `product.md` 必须包含以下章节：

1. **Summary** - 简要功能描述和期望结果
2. **Problem** - 正在解决的用户或产品问题
3. **Goals** - 本次变更必须达成的结果
4. **Non-goals** - 明确排除的范围
5. **Figma / design references** - 链接或明确注明不存在
6. **User experience** - 具体、详尽、可测试的行为描述：
   - 默认行为
   - 状态转换
   - 边缘情况
   - 空状态
   - 错误状态
   - 键盘/交互期望
7. **Success criteria** - 定义正确性的可观察结果
8. **Validation** - 验证方法（测试、截图、手动步骤）
9. **Open questions** - 未解决的产品决策

### Tech Spec 章节

每个 `tech.md` 必须包含以下章节：

1. **Problem** - 技术问题和与产品行为的关系
2. **Relevant code** - 关键文件、类型和入口点（带行号）
3. **Current state** - 系统当前工作方式和限制
4. **Proposed changes** - 实现计划，包含：
   - 变更的模块/组件
   - 新增的类型、API 或状态
   - 数据流和事件流
   - 所有权边界
   - 模式对齐
5. **End-to-end flow** - 主要交互的系统路径
6. **Risks and mitigations** - 失败模式、回归风险、发布风险
7. **Testing and validation** - 需要的测试和验证
8. **Follow-ups** - 延后的清理、扩展、未来工作

### Spec 生命周期

1. Issue 获得标签 `ready-to-spec` → 工作流创建 `specs/issue-<N>/product.md` 和 `tech.md`
2. 人工审核 Spec PR → 批准或请求修改
3. Spec PR 合并 → Issue 获得标签 `plan-approved`
4. Issue 满足实现关口 → 获得标签 `ready-to-implement`
5. 实现开始 → Spec 随行为演进更新
6. 最终 PR 合并 → Spec 反映已交付行为

---

## PR 规范

### 标题格式

```text
[#123] type(scope): summary
```

**示例:**
- `[#42] feat(auth): add OAuth2 support`
- `[#15] fix(api): handle null response`
- `[#7] docs: update conventions`

### Summary 模板

PR 描述必须包含：

```markdown
## What
[一行描述变更内容]

## Why
[变更原因，正在解决的问题]

## How
[关键实现细节]

## Testing
[如何测试]
```

### Metadata 文件

使用 `create-pr` Skill 时，可选提供 `pr-metadata.json`：

```json
{
  "branch_name": "feat/add-retry-logic-42",
  "pr_title": "[#42] feat: add retry logic",
  "pr_summary": "为瞬时 API 失败添加重试逻辑...",
  "intended_files": ["src/api/client.py", "tests/api/test_retry.py"]
}
```

---

## 工作流触发器

### triage-issue.yml

**触发条件:**
- `issues: opened, reopened`
- `issue_comment: created`（非 Bot 评论）
- `workflow_dispatch` 带 `issue` 输入

**输入参数:**
| 参数 | 必需 | 默认值 | 描述 |
|------|------|--------|------|
| `issue` | 是（dispatch） | - | GitHub Issue 编号 |
| `agent_login` | 否 | `AGENT_LOGIN` 变量 | Dispatch 时使用的 Agent 登录名 |
| `include_issue_body` | 否 | `true` | 输出中包含 Issue 正文 Markdown |

**输出:**
- `triage_result.json` - Triage 分类和建议

### create-spec-from-issue.yml

**触发条件:** Issue 获得 `ready-to-spec` 标签

**输出:**
- `specs/issue-<N>/product.md`
- `specs/issue-<N>/tech.md`
- 创建 Spec PR 供人工审核

### plan-approved.yml

**触发条件:** Spec PR 合并（Issue 获得 `plan-approved` 标签）

**行为:**
- 检查实现关口（无冲突、依赖已满足）
- 如果关口通过 → 添加 `ready-to-implement` 标签
- 如果关口失败 → 发布评论说明阻塞原因

### create-implementation-from-issue.yml

**触发条件:** Issue 获得 `ready-to-implement` 标签

**输出:**
- 实现提交
- 实现 PR
- `implementation_summary.md`

### review-pr.yml

**触发条件:**
- `workflow_dispatch` 带 `pr_number` 输入
- `issue_comment: created` 包含 `@AGENT_LOGIN /review`

**输入参数:**
| 参数 | 必需 | 默认值 | 描述 |
|------|------|--------|------|
| `pr_number` | 是（dispatch） | - | Pull Request 编号 |

**输出:**
- `review.json` - Review 结论和评论
- 发布 GitHub PR Review

### respond-to-pr-comment.yml

**触发条件:** PR 评论包含 `@AGENT_LOGIN` 和命令

**命令:**
| 命令 | 用途 |
|------|------|
| `/explain` | 解释代码变更上下文 |
| `/implement` | 实现请求的变更 |
| `/review` | 请求 AI 审核 PR |
| `/fix` | 修复已识别的问题 |
| `/approve` | 批准之前的 REQUEST_CHANGES |

**输出:**
- 在评论线程中实现或解释

### update-pr-review.yml

**触发条件:** 人工修改 Bot PR Review（approve/request_changes）

**行为:**
- 分析人工反馈
- 更新 `review-pr-repo` Companion Skill 指导

### update-dedupe.yml

**触发条件:** 人工将 Issue 关闭为重复

**行为:**
- 分析重复关闭
- 更新 `dedupe-issue-repo` Companion Skill 指导

---

## JSON Schema

### triage_result.json

Triage 工作流输出的完整 Schema：

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
      "description": "从 config.json 中选择的工作流应应用的标签"
    },
    "repro": {
      "type": "string",
      "enum": ["high", "medium", "low", "unknown"],
      "description": "可复现性评估"
    },
    "confidence": {
      "type": "string",
      "enum": ["high", "medium", "low"],
      "description": "Triage 评估的置信度"
    },
    "related_files": {
      "type": "array",
      "items": { "type": "string" },
      "description": "与 Issue 相关的仓库相对文件路径"
    },
    "root_cause": {
      "type": "string",
      "description": "基于证据的根本原因评估"
    },
    "summary": {
      "type": "string",
      "minLength": 1,
      "description": "简短的 Triage 结论"
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
      "description": "向 Issue 作者提问（与 duplicate_of 互斥）"
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
      "description": "重复候选（与 follow_up_questions 互斥）"
    },
    "issue_body": {
      "type": "string",
      "description": "Triage 评论的 Markdown 汇总（当 include_issue_body 为 true 时）"
    }
  },
  "additionalProperties": false
}
```

**约束:**
- `duplicate_of` 和 `follow_up_questions` 互斥
- 如果 `duplicate_of` 非空，`follow_up_questions` 必须为 `[]`
- 如果 `duplicate_of` 有 2+ 候选，包含 `duplicate` 标签（如果可用）
- 绝不在 `labels` 中包含 `plan-approved`, `ready-to-implement`, `ready-to-spec`

### review.json

PR Review 输出的完整 Schema：

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
      "description": "Review 结论"
    },
    "body": {
      "type": "string",
      "minLength": 1,
      "description": "整体 Review 汇总"
    },
    "comments": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["path", "body"],
        "properties": {
          "path": {
            "type": "string",
            "description": "相对于仓库根目录的文件路径"
          },
          "line": {
            "type": "integer",
            "minimum": 1,
            "description": "行内评论的行号"
          },
          "body": {
            "type": "string",
            "minLength": 1,
            "description": "评论内容"
          },
          "side": {
            "type": "string",
            "enum": ["LEFT", "RIGHT"],
            "default": "RIGHT",
            "description": "多侧 Diff 的侧（LEFT=base, RIGHT=head）"
          }
        }
      },
      "description": "特定行的行内评论"
    },
    "recommended_reviewers": {
      "type": "array",
      "items": { "type": "string" },
      "maxItems": 1,
      "description": "推荐的人工审核者登录名（最多一个）"
    }
  },
  "additionalProperties": false
}
```

### pr-metadata.json

使用 `create-pr` 时的 PR Metadata Schema：

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
      "description": "遵循命名规范的分支名"
    },
    "pr_title": {
      "type": "string",
      "description": "遵循标题格式的 PR 标题"
    },
    "pr_summary": {
      "type": "string",
      "description": "可选的 PR 概述"
    },
    "intended_files": {
      "type": "array",
      "items": { "type": "string" },
      "description": "本 PR 意图包含的文件"
    }
  },
  "additionalProperties": false
}
```

### PR_DIFF_V1 格式

Review 工作流使用的 `pr_diff.txt` 格式：

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

**结构:**
- `FILE` 标记文件区域，后跟相对路径
- `LEFT` 和 `RIGHT` 标记 base 和 head commit SHA
- `HUNK` 标记每个 Diff hunk，后跟起始行和行数
- 内容跟在 Hunk header 之后

---

## 最佳实践

### 何时使用本地开发流

使用本地流的情况：
- **快速修复** - 单个开发者，< 1 天工作量
- **小功能** - 无需团队协调
- **个人实验** - 无需 Spec
- **文档更新** - 低风险，独立完成

**本地流优势:**
- 快速迭代
- 开发者完全控制
- 无工作流开销
- 即时反馈

### 何时使用 GitHub 协作流

使用 GitHub 流的情况：
- **多开发者协作** - 共享所有权
- **复杂功能** - 需要 Spec 对齐
- **跨模块变更** - 需要协调
- **生产变更** - 需要审核/批准
- **影响共享 API 的变更** - 团队可见性重要

**GitHub 流优势:**
- 团队可见性
- 结构化审核流程
- Spec 驱动对齐
- 自动化 Triage 和 Review

### 决策矩阵

| 场景 | 推荐流程 | 原因 |
|------|----------|------|
| README 修复错字 | 本地 | 微小，无需协调 |
| 单模块添加日志 | 本地 | 独立，低风险 |
| 重构共享工具 | GitHub | 影响多个调用方 |
| 新 API endpoint | GitHub | 需要 Spec、Review、文档 |
| 性能优化 | GitHub | 需要基准测试、Review |
| 安全修复 | GitHub | 关键，需要彻底 Review |
| 测试文件添加 | 本地（带测试） | 独立 |
| 多文件重构 | GitHub | 需要协调 |

### 工作流集成技巧

1. **先 Triage** - 让自动化分类 Issue 后再手工处理
2. **复杂功能早写 Spec** - Spec 防止实现偏离
3. **提交前本地 Review** - 对风险变更运行 `$review-pr-local`
4. **保持 Spec 更新** - 实现演进时更新 Spec
5. **及时响应 Review 评论** - 使用 `/fix` 或 `/explain` 命令
6. **从 Bot Review 学习** - 人工反馈改进 Companion Skills

### 常见反模式

- **复杂功能跳过 Spec** - 导致实现偏离
- **宽泛暂存** - 只用 `git add <specific-files>`
- **伪造 Issue ID** - 禁止创建带假 Issue 编号的分支
- **未请求强制推送** - 危险，除非明确要求否则避免
- **暂存无关文件** - 保持提交原子性
- **忽略可复现性标签** - 用它们优先处理 Bug 修复

---

## 技能包编写指南

### Repo-Local Companion Skills 的目的

Companion Skills 为仓库特定需求定制核心工作流行为：

- 覆盖特定 Triage 类别
- 定制 Review 指导
- 添加项目特定逻辑
- 从人工反馈学习

### 命名规范

| 核心技能 | Repo Companion |
|----------|----------------|
| `triage-issue` | `triage-issue-repo` |
| `review-pr` | `review-pr-repo` |
| `dedupe-issue` | `dedupe-issue-repo` |

**位置:** `.agents/skills/<skill-name>-repo/SKILL.md`

### 可覆盖类别

#### triage-issue-repo

只有这些类别可以定制：

| 类别 | 允许的定制 |
|------|-----------|
| Area 标签推断 | 映射文件/代码模式到 `area:*` 标签 |
| Type 标签推断 | 映射 Issue 内容到 `bug`/`enhancement`/`documentation` |
| 根本原因建议 | 项目特定的常见原因 |
| 相关文件发现 | 项目特定的文件关系 |

**不可覆盖:**
- 添加/移除保护标签（`ready-to-spec`, `ready-to-implement`, `plan-approved`）
- 重复检测逻辑
- Triage 输出 Schema

#### review-pr-repo

只有这些类别可以定制：

| 类别 | 允许的定制 |
|------|-----------|
| 代码风格规则 | 项目特定的风格偏好 |
| 架构偏好 | 模块边界、所有权规则 |
| 测试覆盖要求 | 项目特定的覆盖期望 |
| 常见反模式 | 项目特定的应避免模式 |

**不可覆盖:**
- Review 结论 Schema
- 评论格式
- 安全 Review 要求

### SKILL.md 模板

```markdown
---
name: <skill-name>-repo
description: 本仓库中 <skill-name> 的仓库特定指导
---

# <skill-name>-repo

[可选：简要描述此 Skill 定制的功能]

## 可覆盖类别

[列出此 Skill 从核心 Skill 覆盖的特定类别]

## 仓库特定规则

### [类别 1：Area 标签推断]

[映射文件/代码到 Area 标签的自定义逻辑]

示例：
- `src/api/*` 中的文件 → 建议 `area:workflow`
- `.agents/skills/*` 中的文件 → 建议 `area:skills`

### [类别 2：根本原因建议]

[此项目中的常见根本原因]

示例：
- API 超时 → 检查限流配置
- 空指针错误 → 检查处理器中的输入验证

### [类别 3：代码风格规则]

[项目特定的风格偏好]

示例：
- 使用 `async/await` 而非回调
- Python 函数优先使用类型提示
- 为公共 API 提供文档和示例

## 集成方式

此 Skill 在以下情况下被核心 `<skill-name>` Skill 调用：
- 核心 Skill 加载仓库特定指导
- `.agents/skills/<skill-name>-repo/SKILL.md` 存在
- 核心 Skill 到达可覆盖决策点

核心 Skill 传递相关上下文，期望此 Skill：
- 在允许覆盖类别内返回建议
- 不修改允许类别之外的输出
- 遵循与核心 Skill 相同的输出 Schema

## 示例

[展示此 Skill 如何改变行为的具体示例]
```

### 实现清单

- [ ] 创建 `.agents/skills/<name>-repo/SKILL.md`
- [ ] 只文档化可覆盖类别
- [ ] 用示例 Issue/PR 测试
- [ ] 验证不破坏核心工作流
- [ ] 从人工反馈更新 Companion Skill（通过 `update-*-repo` 工作流）
- [ ] 如项目级范围，在 `CLAUDE.md` 或 `AGENTS.md` 中文档化

### 常见模式

#### 模式 1：基于 Area 的文件映射

```markdown
## 仓库特定规则

### Area 标签推断

映射文件路径到 Area 标签：
- `src/workflows/*.yml` → `area:workflow`
- `src/scripts/*.py` → `area:workflow`
- `.agents/skills/*/SKILL.md` → `area:skills`
- `specs/**/product.md` → `area:specs`
- `specs/**/tech.md` → `area:specs`
- `tests/**/*` → `area:tests`
```

#### 模式 2：自定义根本原因模板

```markdown
## 仓库特定规则

### 根本原因建议

对于 API 相关 Issue：
- "Connection refused" → 检查服务是否运行，验证端口配置
- "Timeout exceeded" → 检查限流，验证网络连接
- "Unauthorized" → 检查令牌有效性，验证权限范围

对于工作流相关 Issue：
- "Workflow failed" → 检查工作流语法，验证 Action 权限
- "Action timeout" → 检查步骤超时设置，验证资源限制
```

#### 模式 3：项目特定术语

```markdown
## 仓库特定规则

### 术语映射

- "AICodingFlow" 指此工作流系统（非通用 AI coding）
- "Spec-driven" 指实现前先写 product.md + tech.md
- "Companion skill" 指仓库本地 `-repo` Skill 变体
- "Protected labels" 指工作流关口标签（ready-to-spec 等）
```

### 测试 Companion Skills

提交前手动测试 Companion Skills：

```bash
# 测试 triage-issue-repo
python3 .github/scripts/prepare_issue_triage_context.py \
  --repo <repo> --issue <number> \
  --output triage_context.json

# 用核心和 Repo Skill 运行 OpenCode
# 检查 triage_result.json 是否符合预期行为

# 测试 review-pr-repo
python3 .github/scripts/prepare_local_review_inputs.py

# 用核心和 Repo Skill 运行 OpenCode
# 检查 review.json 是否符合预期行为
```

### 从人工反馈更新

Companion Skills 通过专用工作流自动更新：

| 工作流 | 触发条件 | 更新目标 |
|--------|----------|----------|
| `update-pr-review.yml` | 人工修改 Bot PR Review | 更新 `review-pr-repo` |
| `update-dedupe.yml` | 人工将 Issue 关闭为重复 | 更新 `dedupe-issue-repo` |

这些工作流：
- 分析人工反馈模式
- 生成 Skill 更新建议
- 将更新提交到 Companion Skill 文件

---

## 附录：快速参考

### 分支类型

| 类型 | 使用场景 |
|------|----------|
| `feat` | 新功能或能力 |
| `fix` | Bug 修复 |
| `refactor` | 代码重构 |
| `docs` | 文档 |
| `test` | 测试 |
| `perf` | 性能 |
| `chore` | 维护 |
| `spec` | 仅 Spec 变更 |
| `impl` | 从 Spec 实现 |

### 提交类型

| 类型 | 使用场景 |
|------|----------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构 |
| `perf` | 性能 |
| `docs` | 文档 |
| `test` | 测试 |
| `build` | 构建系统 |
| `ci` | CI/CD |
| `chore` | 维护 |

### 保护标签（禁止自动添加）

- `ready-to-spec`
- `ready-to-implement`
- `plan-approved`

### PR 命令

| 命令 | 用途 |
|------|------|
| `/explain` | 解释代码变更 |
| `/implement` | 实现请求的变更 |
| `/review` | 请求 AI 审核 |
| `/fix` | 修复已识别的问题 |
| `/approve` | 批准之前的拒绝 |