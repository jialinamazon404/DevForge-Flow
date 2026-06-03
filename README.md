# DevForge-Flow (AICodingFlow)

> AI Coding 工作流模板系统 —— 连接本地 OpenCode Skills、GitHub Actions、PR Review 自动化、Issue Triage 和 Spec 驱动开发，从规划到合并的稳定、可复现路径。

---

## 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [配置](#配置)
- [使用指南](#使用指南)
  - [本地开发流 Skills](#本地开发流-skills)
  - [GitHub 协作流 Workflows](#github-协作流-workflows)
- [项目初始化（project-init）](#项目初始化project-init)
- [团队工作流图](#团队工作流图)
- [快速参考](#快速参考)
- [目录结构](#目录结构)
- [文档索引](#文档索引)
- [贡献与反馈](#贡献与反馈)

---

## 概述

DevForge-Flow 提供两类核心能力：

| 流程 | 工具 | 适用场景 |
|------|------|----------|
| **本地开发流** | `create-issue`、`git-*`、`create-pr` Skills | 快速修复、小功能、个人实验 |
| **GitHub 协作流** | GitHub Actions + OpenCode | 团队协作、复杂功能、Spec 驱动开发 |

### 核心特性

| 特性 | 说明 |
|------|------|
| 🔧 **Spec 驱动开发** | `ready-to-spec` → product.md + tech.md → `plan-approved` → 自动触发实现 |
| ✅ **Spec 一致性校验** | 实现 PR 自动比对 product.md/tech.md，输出差异报告 |
| 📦 **Spec 归档** | 实现合并后自动标记 `implemented`，或手动标记 `deprecated` |
| 🤖 **自动化 Triage** | 新 Issue 自动分类、标签、复现性评估、重复检测 |
| 👁️ **AI PR Review** | 自动审查 PR，生成 APPROVE/REJECT verdict + inline comments |
| 🔄 **闭环学习** | 人工反馈自动更新 Companion Skills（`review-pr-repo`, `dedupe-issue-repo`） |
| 🛡️ **安全护栏** | 保护标签控制、禁止伪造 Issue ID、禁止 force push |
| 🖥️ **本地辅助脚本** | 无 GHA 时也可手动创建 spec、校验实现、归档状态 |
| 📋 **需求编号追踪** | Issue 创建时输入 SNXXX，自动传递到提交消息和 PR 标题 |

---

## 快速开始

### 一行安装（完整版）

```bash
curl -fsSL https://raw.githubusercontent.com/jialinamazon404/DevForge-Flow/main/install.sh | bash -s -- --target /path/to/target-repo
```

### 一行安装（精简版 — 无 AI 依赖）

> 不需要 `AGENT_API_KEY`，仅安装 CI 测试 + Spec 归档等非 AI 工作流，
> 本地 Skills 和脚本仍可正常使用。

```bash
curl -fsSL https://raw.githubusercontent.com/jialinamazon404/DevForge-Flow/main/install.sh | bash -s -- --target /path/to/target-repo --lite
```

### 克隆安装

```bash
git clone https://github.com/jialinamazon404/DevForge-Flow.git
cd DevForge-Flow

# 完整版（含 AI 工作流）
./install.sh --target /path/to/target-repo

# 精简版（不含 AI 工作流）
./install.sh --target /path/to/target-repo --lite
```

### 预览变更

```bash
./install.sh --target /path/to/target-repo --dry-run
./install.sh --target /path/to/target-repo --lite --dry-run
```

### 依赖

安装脚本需要：`bash`、`git`、`rsync`（一行安装还需 `curl`）

**安装模式对比**：

| 内容 | 完整版 | 精简版 (`--lite`) |
|------|--------|-------------------|
| `.agents/skills/` | ✅ 全部 | ✅ 全部（本地仍可用） |
| `scripts/` | ✅ | ✅ |
| `.github/scripts/` | ✅ | ✅ |
| `.github/aicodingflow-tests/` | ✅ | ✅ |
| `.github/workflows/ci.yml` | ✅ 含 `ai-review` job | ✅ 精简版（仅 test + compile） |
| AI 工作流（triage、spec、impl、review、verify、respond、update-*） | ✅ 8 个 | ❌ 不安装 |
| 非 AI 工作流（plan-approved、archive-spec、generate-project-history） | ✅ 4 个 | ✅ 4 个 |
| 需要 `AGENT_API_KEY` | ✅ | ❌ |

---

## 配置

安装后在目标仓库配置以下 Secrets 和 Variables：

### 必需配置

| 名称 | 类型 | 用途 |
|------|------|------|
| `AGENT_API_KEY` | Secret | OpenCode API Key（如 Anthropic API Key） |
| `AGENT_MODEL` | Variable | 模型名称，如 `anthropic/claude-sonnet-4-20250514` |
| `AGENT_LOGIN` | Variable | Agent GitHub 登录名，用于 Issue/PR mention |

### 可选配置

| 名称 | 类型 | 用途 |
|------|------|------|
| `REVIEW_BOT_LOGIN` | Variable | Review Bot 登录名（默认 `github-actions[bot]`） |
| `APP_CLIENT_ID` | Variable | GitHub App Client ID（用于更新 workflow 文件） |
| `APP_PRIVATE_KEY` | Secret | GitHub App Private Key（需 `Contents` + `Workflows` 写权限） |

### 初始化 Triage 配置

首次接入时，在 OpenCode 运行：

```text
$bootstrap-issue-config
```

自动生成：
- `.github/issue-triage/config.json` — Label 定义
- `.github/CODEOWNERS` — 代码所有权

---

## 安装模式详解

### 完整版（默认）

安装所有 GitHub Actions 工作流 + 全量 Skills + 辅助脚本，**需要配置 `AGENT_API_KEY`**。

适用场景：团队有 Anthropic API Key，希望 GitHub 上的 Issue、Spec、PR 等环节由 AI 自动介入。

**工作流清单**（12 个）：

| 工作流 | 触发方式 | AI 依赖 | 功能 |
|--------|----------|----------|------|
| `ci.yml` | PR push | ✅ ai-review job | 运行测试 + 编译 + AI PR Review |
| `triage-issue.yml` | Issue open/edit | ✅ | 自动分类、标签、复现性评估 |
| `create-spec-from-issue.yml` | `ready-to-spec` 标签 | ✅ | AI 生成 product.md + tech.md |
| `create-implementation-from-issue.yml` | `ready-to-implement` 标签 | ✅ | AI 自动实现代码 |
| `review-pr.yml` | CI dispatch | ✅ | AI PR Review + inline comments |
| `verify-impl-against-spec.yml` | PR push（有 spec） | ✅ | AI 对齐 Spec ↔ 实现 |
| `respond-to-pr-comment.yml` | `/fix` PR comment | ✅ | AI 修改代码回应 PR comment |
| `update-pr-review.yml` | 定时 / dispatch | ✅ | 从人工反馈学习更新 Review Skill |
| `update-dedupe.yml` | 定时 / dispatch | ✅ | 从重复关闭学习更新 Dedupe Skill |
| `plan-approved.yml` | `plan-approved` 标签 | ❌ | 同步 Issue 状态（标签/assignee） |
| `archive-spec.yml` | PR merge / dispatch | ❌ | 归档 Spec 状态（implemented/deprecated） |
| `generate-project-history.yml` | 定时 / dispatch | ❌ | 生成项目历史文档 |

### 精简版（`--lite` / `--local`）

仅安装不需要 AI 的工作流 + 全量 Skills + 辅助脚本，**不需要 `AGENT_API_KEY`**。

适用场景：没有 Anthropic API Key，或不希望 AI 自动介入 GitHub 协作环节，但仍想使用本地开发 Skills。

**工作流清单**（4 个）：

| 工作流 | 触发方式 | 功能 |
|--------|----------|------|
| `ci.yml`（精简版） | PR push | 运行测试 + 编译（无 ai-review job） |
| `plan-approved.yml` | `plan-approved` 标签 | 同步 Issue 状态 |
| `archive-spec.yml` | PR merge / dispatch | 归档 Spec 状态 |
| `generate-project-history.yml` | 定时 / dispatch | 生成项目历史文档 |

**未安装的工作流**（8 个，均需要 `AGENT_API_KEY`）：

- `triage-issue.yml` — Issue 自动分类
- `create-spec-from-issue.yml` — AI 生成 Spec
- `create-implementation-from-issue.yml` — AI 自动实现
- `review-pr.yml` — AI PR Review
- `verify-impl-against-spec.yml` — AI Spec 对齐
- `respond-to-pr-comment.yml` — `/fix` PR comment 响应
- `update-pr-review.yml` — Review 学习
- `update-dedupe.yml` — Dedupe 学习

**精简版 CI 的区别**：

| 项目 | 完整版 CI | 精简版 CI |
|------|-----------|----------|
| `permissions` | `actions: write`, `contents: read` | `contents: read` |
| `test` job | ✅ 单元测试 + py_compile | ✅ 单元测试 + py_compile（相同） |
| `ai-review` job | ✅ dispatch review-pr.yml | ❌ 不存在 |

### 两种模式共有的内容

无论完整版还是精简版，以下内容始终安装：

| 内容 | 说明 |
|------|------|
| `.agents/skills/` | 全量 Skills（本地 OpenCode/Qoder 可直接调用） |
| `.github/scripts/` | Python 辅助脚本 |
| `.github/aicodingflow-tests/` | 测试和 fixtures |
| `scripts/` | 本地脚本（new-spec、verify-impl、archive-spec） |

### 如何升级到完整版

精简版随时可升级为完整版：

1. 在目标仓库 Settings > Secrets and Variables 中配置：
   - **Secret**: `AGENT_API_KEY`（Anthropic API Key）
   - **Variable**: `AGENT_MODEL`（如 `anthropic/claude-sonnet-4-20250514`）
   - **Variable**: `AGENT_LOGIN`（Agent GitHub 登录名）
2. 重新运行安装（不带 `--lite`）：
   ```bash
   ./install.sh --target /path/to/target-repo
   ```
3. 安装脚本会用 rsync 同步缺失的 AI 工作流，并覆盖精简版 `ci.yml` 为完整版。

---

## 使用指南

### 本地开发流 Skills

> 本地 Skills 在 OpenCode 中按名称调用，如 `$create-issue`、`$git-branch`

---

#### 📝 create-issue

**用途**：从对话上下文创建 GitHub Issue

**工作流**：
1. 查找仓库根目录和 Issue 模板
2. 分类请求 → 选择模板（bug/feature/docs）
3. 安全报告 → 私有渠道（禁止公开敏感细节）
4. **询问 SNXXX** → 用户输入需求编号（如 `SN001`），可选跳过
5. 构建标题/正文（含 SNXXX 元数据：标题前缀 + 正文 HTML 注释）
6. `gh issue create` 提交

**关键参数**（隐含于上下文）：

| 参数 | 来源 | 说明 |
|------|------|------|
| 模板选择 | 请求类型 | bug → bug 模板，feature → feature 模板 |
| Labels | 默认不添加 | 让 Triage 工作流自动分类 |
| Assignees | 明确请求时 | 不自动添加 |

**安全规则**：
- ❌ 禁止公开 secrets、credentials、private keys
- ❌ 禁止 raw HTTP fallback（只用 GitHub CLI）
- ❌ 禁止从此 Skill 创建 labels/milestones/branches/PRs

---

#### 🌿 git-branch

**用途**：创建符合仓库规范的分支

**命名格式**：`<type>/<short-desc>-<issueID>`

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构 |
| `docs` | 文档 |
| `test` | 测试 |
| `spec` | 仅 Spec |
| `impl` | 从 Spec 实现 |

**工作流**：
1. 从 Issue 或用户输入确定分支名
2. `git check-ref-format --branch` 验证名称
3. 检查本地/远程状态
4. `git switch -c <branch> <base>` 创建

**参数**：

| 参数 | 来源 | 默认值 |
|------|------|--------|
| `type` | Issue 上下文 | `chore` |
| `short-desc` | Issue 标题（`gh issue view`） | - |
| `issueID` | 上下文引用 | - |
| `base` | 仓库指导 | `main` |

**安全规则**：
- ❌ 禁止 overwrite/reset/stash/delete（除非明确请求）
- ❌ 禁止创建保护分支（`main`/`master`/`develop`）
- ❌ 禁止伪造 Issue ID

---

#### 🏠 git-worktree

**用途**：创建隔离 Git Worktree 用于并行工作

**工作流**：
1. 确定路径（`.worktrees/<branch>`）
2. 检查冲突
3. `git worktree add <path> <branch>`
4. 报告位置

**参数**：

| 参数 | 来源 | 默认值 |
|------|------|--------|
| `path` | 用户输入 | `.worktrees/<branch>` |
| `branch` | 上下文 | - |
| `base` | 新分支时 | `main` |

**安全规则**：
- ❌ 禁止移除 Worktree（除非明确请求）
- ✅ `.worktrees/` 必须保留在 `.gitignore`

---

#### 💾 git-commit

**用途**：从真实 Diff 创建原子提交

**提交格式**：`SNXXX: type(scope): summary`

**SNXXX 来源**：
- Issue 正文 HTML 注释：`<!-- SNXXX: SN001 -->`（优先）
- Issue 标题前缀：`SN001: issue title`（备用）
- 历史 Issue 无 SNXXX 时：使用标准格式（无 SNXXX 前缀）

**Issue 关联**：
- `Fixes #123` — 关闭 Issue
- `Refs #123` — 部分/准备工作

**工作流**：
1. `git status` / `git diff` 检查变更
2. 确定提交边界（分离关注点）
3. 只暂存意图文件
4. Conventional Commit 格式构建消息
5. Hooks 启用提交

**参数**：

| 参数 | 来源 | 默认值 |
|------|------|--------|
| `type` | 变更性质 | `feat`/`fix` 等 |
| `scope` | 模块 | 可选 |
| `summary` | Diff 描述 | 从 Diff |
| `issueID` | 分支模式或显式 | - |

**安全规则**：
- ❌ 禁止 `--no-verify`（除非明确请求）
- ❌ 禁止 push/重写历史/force
- ✅ 报告 Hook 失败，不绕过

---

#### ⬆️ git-push

**用途**：安全推送已提交分支

**工作流**：
1. 验证分支已提交
2. 检查远程状态（无分歧）
3. `git push -u origin <branch>`

**参数**：

| 参数 | 来源 | 默认值 |
|------|------|--------|
| `remote` | 仓库配置 | `origin` |
| `branch` | 当前分支 | - |
| `force` | 永不 | `false` |

**安全规则**：
- ❌ 禁止 force push（除非明确请求）
- ✅ 分歧时警告，不自动解决

---

#### 🔀 create-pr

**用途**：创建或更新 GitHub Pull Request

**标题格式**：`[#123] type(scope): summary`

**Summary 模板**：
```markdown
## What
[一行描述]

## Why
[变更原因]

## How
[关键实现]

## Testing
[如何测试]
```

**工作流**：
1. 验证分支已推送
2. 如需与 base 同步
3. 构建 PR 标题/正文
4. `gh pr create`
5. 关联 Issue

**参数**（从 `pr-metadata.json` 或上下文）：

| 参数 | 来源 | 必需 |
|------|------|------|
| `branch_name` | 上下文 | ✅ |
| `pr_title` | 上下文 | ✅ |
| `pr_summary` | 上下文 | 可选 |
| `intended_files` | 上下文 | 可选 |

**安全规则**：
- ✅ 请求时先运行 Review
- ❌ 禁止合并/关闭 PR

---

#### 🚀 project-init

**用途**：首次接触项目时，自动分析项目历史、架构、技术栈和 Spec 状态，生成项目概览并持久化到 `.agents/AGENTS.md`

**调用方式**：在 OpenCode/Qoder 中运行 `$project-init` 或说「帮我了解这个项目」

**8 步工作流**：

| Step | 动作 | 说明 |
|------|------|------|
| 1 | 检测项目基础信息 | 读取 `package.json` / `pyproject.toml` / `go.mod` 等推断技术栈 |
| 2 | 分析 Git 历史 | 提取提交数、活跃分支、关键贡献者 |
| 3 | 理解项目结构 | 构建目录用途映射 |
| 4 | 检查 AICodingFlow 集成 | 识别安装模式（full/lite）、已安装的 Skills 和 Workflows |
| 5 | 评估与初始化 Spec 结构 | 三种场景处理（详见下方） |
| 6 | 检测团队规范 | 读取 `.editorconfig`、`conventions.md`、`CODEOWNERS` 等 |
| 7 | 生成项目概览 | 结构化 Markdown 概览（技术栈、历史、规范、入门指南） |
| 8 | 更新 Agent 上下文 | 将概览写入 `.agents/AGENTS.md` 供后续会话引用 |

### Step 5 详解：Spec 评估与初始化

project-init 对项目 Spec 状况进行分场景处理：

**场景 A — 无 Spec**：

> 项目没有任何 Spec 文件。
> 是否创建一个 project-overview 基线 Spec（product + tech）？

创建流程：`create-issue` → `create-product-spec` → `create-tech-spec`，
生成 `specs/issue-N/product.md` + `tech.md` 作为项目现状快照。

**场景 B — 存在非标准 Spec**：

> 发现以下不符合 AICodingFlow 约定的 Spec 文件：
>
> Pattern 1（目录约定不同，文件结构正确）：
>   `specs/feature-X/product.md` + `tech.md` → 迁移工作量低（仅重命名目录）
> Pattern 2（文件结构不同）：
>   `SPEC.md`、`ARCHITECTURE.md` → 迁移工作量中等（内容重组 + 目录重组）
>
> 选择操作：1. 迁移 | 2. 新建基线 | 3. 跳过

| Pattern | 例子 | 迁移工作量 |
|---------|------|------------|
| Pattern 1 | `specs/feature-X/product.md` + `tech.md`（不是 `specs/issue-N/`） | 低 — 仅重命名目录 |
| Pattern 2 | `SPEC.md`、`ARCHITECTURE.md`（不是 `product.md` + `tech.md`） | 中 — 重组内容 |
| Pattern 3 | README、CHANGELOG（不是 Spec） | 无 — 保留原位 |

**场景 C — 已有合规 Spec**：

跳过初始化，但会检查 **Spec 生命周期状态**：

| 状态 | 含义 | 成熟项目期望 |
|------|------|-------------|
| `active` | 进行中 | 应很少或为零 |
| `implemented` | 已实现已归档 | 大多数 Spec 应为此状态 |
| `deprecated` | 已弃用 | 部分可能存在 |
| `unknown` | 未标记（旧 Spec） | 需要补充 frontmatter |

如果成熟项目中发现 `status: active` 的 Spec，会询问是否归档：
- 读取 Spec 内容，检查功能是否已在代码中实现 → 建议归档为 `implemented`
- 功能被取消或移除 → 建议归档为 `deprecated`
- 使用 `scripts/archive-spec.py` 更新 frontmatter

**Issue 编号约定**：

创建基线 Spec 时会询问 Issue 编号方式：

| 方式 | 说明 | 适用场景 |
|------|------|----------|
| 自动分配 | 让 GitHub 分配下一个编号 | 新项目，最简单 |
| 自定义引用 | 创建更有意义的 Issue 标题 | 需要编号更有语义 |
| 映射已有 Issue | 匹配迁移 Spec 对应的现有 Issue | Pattern 1 迁移 |

---

### GitHub 协作流 Workflows

> GitHub Actions 自动化 Triage、Spec 创建、Implementation、Review

---

#### 🔍 triage-issue.yml

**触发条件**：
- `issues: opened, reopened`
- `issue_comment: created`（非 Bot）
- `workflow_dispatch` 带 `issue` 输入

**输入参数**：

| 输入 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `issue` | ✅（dispatch） | - | Issue 编号 |
| `agent_login` | 可选 | `AGENT_LOGIN` | Agent 登录 |
| `include_issue_body` | 可选 | `true` | 包含 Issue 正文 |

**输出**：`triage_result.json`

| 字段 | 类型 | 说明 |
|------|------|------|
| `labels` | `array[string]` | 要应用的标签 |
| `repro` | `string` | 复现性（`high`/`medium`/`low`/`unknown`） |
| `confidence` | `string` | 置信度（`high`/`medium`/`low`） |
| `related_files` | `array[string]` | 相关文件路径 |
| `root_cause` | `string` | 根本原因评估 |
| `summary` | `string` | Triage 结论 |
| `follow_up_questions` | `array` | 向作者提问 |
| `duplicate_of` | `array` | 重复候选 |

**约束**：
- ❌ 禁止包含保护标签（`ready-to-spec`/`ready-to-implement`/`plan-approved`）
- `duplicate_of` 和 `follow_up_questions` 互斥

---

#### 📋 create-spec-from-issue.yml

**触发**：Issue 获得 `ready-to-spec` 标签

**输出**：
- `specs/issue-<N>/product.md` — Product Spec（行为、UX）
- `specs/issue-<N>/tech.md` — Tech Spec（架构、实现）
- Spec PR 供人工审核

---

#### ✅ plan-approved.yml

**触发**：Spec PR 获得 `plan-approved` 标签

**行为**（自动串联）：
- 移除 issue 的 `ready-to-spec` 标签
- **自动添加** `ready-to-implement` 标签并 assign bot
- **自动触发** implementation workflow（无需人工干预）

---

#### 🔨 create-implementation-from-issue.yml

**触发**：Issue 获得 `ready-to-implement`

**输出**：
- Feature 分支上的实现提交
- 实现 PR
- `implementation_summary.md`

---

#### ✅ verify-impl-against-spec.yml (New)

**触发**（自动）：实现 PR 被创建或更新（`pull_request: [opened, synchronize]`）

**跳过条件**：纯 spec 文件变更（`specs/` 目录）— 跳过验证

**行为**：
- 用 `check-impl-against-spec` 技能比对实现 diff 与 `product.md` / `tech.md`
- 输出 `spec-alignment-report.md`
- 显示为 GitHub check run `Spec Alignment Check`
- 不阻塞合并（仅供审查参考）

---

#### 📦 archive-spec.yml (New)

**自动触发**：实现 PR 被合并（PR body 含 `Closes #N`）→ 自动将 spec 标记为 `implemented`

**手动触发**：`workflow_dispatch`，参数 `issue`、`status`（`implemented`/`deprecated`）、`pr_number`、`reason`

**行为**：
- 在 `specs/issue-N/product.md` 顶部更新 YAML frontmatter
- 自动添加 `status: implemented` / `deprecated` 及相关元数据
- 提交到分支 `feat/archive-spec-N`，创建 PR

| 状态 | 说明 | 设置方式 |
|------|------|----------|
| `active` | 进行中（默认） | 新 spec 自动 |
| `implemented` | 已实现 | PR 合并自动 / workflow_dispatch |
| `deprecated` | 已弃用 | workflow_dispatch |
| `unknown` | 未标记 | 旧 spec 兼容 |

---

#### 👁️ review-pr.yml

**触发**：
- `workflow_dispatch` 带 `pr_number`
- PR 评论含 `@AGENT_LOGIN /review`

**输入**：

| 输入 | 必需 | 说明 |
|------|------|------|
| `pr_number` | ✅（dispatch） | PR 编号 |

**输出**：`review.json`

| 字段 | 类型 | 说明 |
|------|------|------|
| `verdict` | `string` | `APPROVE`/`REJECT`/`COMMENT` |
| `body` | `string` | Review 汇总 |
| `comments` | `array` | 行内评论 |
| `recommended_reviewers` | `array` | 人工审核者（最多 1） |

---

#### 💬 respond-to-pr-comment.yml

**触发**：PR 评论含 `@AGENT_LOGIN` + `/fix` 命令

**命令**：

| 命令 | 用途 | Workflow |
|------|------|----------|
| `/fix` | 修复问题或实现变更 | `respond-to-pr-comment.yml` |
| `/review` | 请求 AI Review | `review-pr.yml` |

> `/explain`、`/implement`、`/approve` 为规划中的命令，当前未实现。

---

#### 🔄 update-pr-review.yml

**触发**：人工修改 Bot PR Review

**行为**：更新 `review-pr-repo` Companion Skill

---

#### 🔍 update-dedupe.yml

**触发**：人工将 Issue 关闭为重复

**行为**：更新 `dedupe-issue-repo` Companion Skill

---

### 本地辅助脚本

> 无 GitHub Actions 时，用 `scripts/` 下的脚本手动执行 Spec 生命周期操作。
> 仅依赖 git + Python 标准库，不需要 `gh` CLI 或 API key。

| 脚本 | 用途 | 用法 |
|------|------|------|
| `new-spec.sh` | 创建 spec 模板（含 frontmatter） | `scripts/new-spec.sh <issue-number> [title]` |
| `verify-impl.py` | 本地比对实现 vs spec | `scripts/verify-impl.py <issue-number> [base-ref]` |
| `archive-spec.py` | 本地更新 spec 状态 frontmatter | `scripts/archive-spec.py <issue-number> <status> [value]` |

---

## 团队工作流图

### 整体协作流程

```mermaid
flowchart TB
    subgraph Local["本地开发流"]
        A[发现 Issue/需求] --> B[create-issue]
        B --> C[git-branch]
        C --> D[开发实现]
        D --> E[git-commit]
        E --> F[git-push]
        F --> G[create-pr]
    end
    
    subgraph GitHub["GitHub 协作流"]
        H[Issue 创建] --> I[triage-issue]
        I --> J{需要 Spec?}
        J -->|是| K[create-spec]
        K --> L[plan-approved]
        L --> M[create-impl]
        J -->|否| N[直接实现]
        N --> O[PR 创建]
        M --> O
        O --> P[review-pr]
        P --> Q{Review 结果}
        Q -->|approve| R[合并]
        Q -->|changes| S[respond]
        S --> D
    end

    subgraph Verify["验证 & 归档"]
        R --> V[verify-impl-against-spec]
        V --> A2[archive-spec]
    end
    
    G --> O
```

### 流程选择决策

```mermaid
flowchart LR
    A[开始任务] --> B{团队协作?}
    B -->|否| C[本地流]
    B -->|是| D{需要 Spec?}
    D -->|否| E[GitHub 流<br/>直接实现]
    D -->|是| F[GitHub 流<br/>Spec 先行]
    
    C --> G[快速完成<br/>完全控制]
    E --> H[团队可见<br/>轻量流程]
    F --> I[充分规划<br/>审核把关]
```

---

## 快速参考

### 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能 | `feat/<desc>-<issue>` | `feat/add-retry-42` |
| 修复 | `fix/<desc>-<issue>` | `fix/null-input-15` |
| 重构 | `refactor/<desc>-<issue>` | `refactor/auth-33` |
| 文档 | `docs/<desc>-<issue>` | `docs/readme-7` |
| 测试 | `test/<desc>-<issue>` | `test/unit-21` |
| Spec | `spec/<desc>-<issue>` | `spec/api-99` |
| 实现 | `impl/<desc>-<issue>` | `impl/auth-99` |

### 提交格式

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能 | `SNXXX: feat(scope): summary` | `SN001: feat(auth): add OAuth2` |
| 修复 | `SNXXX: fix(scope): summary` | `SN002: fix(api): handle null` |
| 文档 | `SNXXX: docs: summary` | `SN003: docs: update readme` |

### Issue Labels

| 类别 | Labels | 用途 |
|------|--------|------|
| **保护** | `ready-to-spec`, `ready-to-implement`, `plan-approved` | 工作流关口（由 workflow 自动管理） |
| 流程 | `triaged`, `needs-info`, `duplicate` | Triage 处置 |
| 复现 | `repro:high`, `repro:medium`, `repro:low`, `repro:unknown` | 复现性 |
| 区域 | `area:workflow`, `area:skills`, `area:specs`, `area:tests` | 代码区域 |
| 类型 | `bug`, `enhancement`, `documentation` | Issue 类型 |

### PR 命令

| 命令 | 用途 | Workflow |
|------|------|----------|
| `/fix` | 修复问题或实现变更 | `respond-to-pr-comment.yml` |
| `/review` | 请求 AI Review | `review-pr.yml` |

> `/explain`、`/implement`、`/approve` 为规划中的命令，当前未实现。

---

## 目录结构

```
.agents/                         # 多工具共享 Agent 配置
.agents/skills/                  # OpenCode/Codex Skills
    project-init/            # 项目初始化与 Spec 评估 Skill
.claude/                         # Claude 入口
.cursor/rules/                   # Cursor rules
.github/workflows/               # GitHub Actions
.github/scripts/                 # Python 辅助脚本
.github/aicodingflow-tests/      # 测试和 fixtures
.github/tests/                   # 自用测试
.github/issue-triage/            # Triage 配置
scripts/                         # 本地辅助脚本（无 GHA 依赖）
docs/                            # 详细文档
specs/                           # Issue Spec 目录
```

---

## 文档索引

| 文档 | 语言 | 内容 |
|------|------|------|
| [Conventions](docs/conventions.md) | 英文 | Git/Label/Spec/PR 规范、JSON Schema、最佳实践 |
| [规范文档](docs/conventions_CN.md) | 中文 | Git/Label/Spec/PR 规范（中文版） |
| [README_CN](docs/README_CN.md) | 中文 | 本文档中文版 |
| [本地开发流](docs/local-development-flow.md) | 中文 | Local Skills 详细说明 |
| [GitHub 协作流](docs/github-collaboration-flow.md) | 中文 | GitHub Actions 详细说明 |
| [Agent 目录](docs/agent-directories.md) | 中文 | `.agents`/`.claude`/`.cursor` 结构 |
| [自进化 Skills](docs/evolving-repo-skills.md) | 中文 | Companion Skill 自动更新 |
| [项目历史](docs/PROJECT-HISTORY.md) | 中英 | Spec 项目时间线与状态索引 |

---

## 贡献与反馈

提交 Issue 或 PR 反馈。Bug 报告请包含：

- 📌 运行的 Skill 或 Workflow
- 🌿 分支名、Issue 编号、PR 链接
- 📝 命令输出或 GitHub Actions 日志
- 📦 Artifacts：
  - PR Review: `pr_description.txt`, `pr_diff.txt`, `spec_context.md`, `review.json`
  - Implementation: `issue_context.json`, `implementation_summary.md`, `pr-metadata.json`

### 测试命令

```bash
python3 -m unittest discover -s .github/tests
python3 -m unittest discover -s .github/aicodingflow-tests
```

---

> **License**: MIT | **Author**: jialin.chen | **Repo**: [jialinamazon404/DevForge-Flow](https://github.com/jialinamazon404/DevForge-Flow)