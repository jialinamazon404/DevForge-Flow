# 本地开发流

本地开发流适合开发者在自己的机器上与 Codex 协作完成常规改动：

```text
request -> issue -> branch/worktree -> commit -> push -> pr -> review -> merge
```

它的目标是让 issue、分支、提交和 PR 都可审查、可回滚、可复现。

## 使用前准备

在目标仓库安装 AICodingFlow：

```bash
./install.sh --target /path/to/target-repo
```

本地使用 GitHub 相关 SKILL 时，需要：

- 已安装并登录 `gh`。
- 当前仓库有可访问的 GitHub remote。
- Codex 能读取 `.agents/skills/`。

## 相关 SKILL

| SKILL | 用途 |
| --- | --- |
| `create-issue` | 根据当前对话或用户输入选择 `.github` issue 模板并创建 GitHub issue。 |
| `git-branch` | 根据 issue 或任务描述创建规范分支。 |
| `git-worktree` | 为并行 issue 或任务创建独立 worktree。 |
| `git-commit` | 从真实 diff 中整理原子提交。 |
| `git-push` | 安全推送分支，避免误推 base 分支或强推。 |
| `create-pr` | 创建或更新 GitHub PR。 |
| `diagnose-ci-failures` | 拉取 PR、branch 或 run 的 CI 失败日志并生成修复计划。 |
| `resolve-merge-conflicts` | 在 merge、rebase、cherry-pick 或 stash pop 冲突时提取并解决冲突。 |

## 典型用法

### 1. 创建 issue

```text
$create-issue
```

`create-issue` 会读取目标仓库的 `.github/ISSUE_TEMPLATE`，根据请求选择最合适的模板，保守填充 issue 标题和正文，并用 `gh issue create` 创建 issue。它默认不添加分类 labels；新 issue 打开后由 `triage-issue.yml` 自动应用 triage labels。

### 2. 创建分支

```text
$git-branch #47
```

`git-branch` 会读取 issue，推断 Conventional Commit 类型，生成 `<type>/<short-desc>-<issueID>` 格式的分支名，并从合适的 base 创建分支。

示例：

```text
docs/optimize-readme-47
```

### 3. 创建并行 worktree

```text
$git-worktree #48
```

`git-worktree` 会在 `.worktrees/<branch-name>` 下创建独立工作目录，适合同时处理多个 issue。它不会复制当前工作树里的未提交改动；Codex 后续 tool calls 会默认从新 worktree 运行，并输出你自己的 shell 需要执行的 `cd .worktrees/<branch-name>`。

### 4. 整理提交

```text
$git-commit
```

`git-commit` 会读取工作区状态、diff stat、完整 diff 和 staged diff，判断是否需要拆分提交，精确 stage 目标文件，并使用规范提交信息。

### 5. 推送分支

```text
$git-push
```

`git-push` 会检查当前分支、upstream 和待推送提交。没有 upstream 时执行 `git push -u origin <branch>`；已有 upstream 时执行普通 `git push`。它不会默认 force push，也会避免直接推送 `main`、`master`、`develop` 等共享 base 分支。

### 6. 创建或更新 PR

```text
$create-pr
```

`create-pr` 会检查 base diff，确认 base 分支已合入当前分支，生成包含 summary、validation 和 issue link 的 PR 描述。如果当前分支已有 PR，它会更新已有 PR，而不是重复创建。

## 本地 review

需要在本地模拟 GitHub PR Review 时，可以使用：

```text
$review-pr-local
$review-spec-local
```

它们会从当前分支准备 `pr_description.txt`、`pr_diff.txt` 和可选 `spec_context.md`，运行对应 review skill，并验证 `review.json`。本地 review 不会发布 GitHub 评论。

## 测试

AICodingFlow 本仓库的测试命令：

```bash
python3 -m unittest discover -s .github/tests
python3 -m unittest discover -s .github/aicodingflow-tests
```

修改 workflow、review 或 implementation 相关脚本后，建议额外编译检查：

```bash
PYTHONPYCACHEPREFIX=/tmp/aicodingflow-pycache python3 -m py_compile \
  .github/scripts/*.py \
  .agents/skills/implement-specs/scripts/*.py \
  .agents/skills/review-pr/scripts/validate_review_json.py \
  .agents/skills/update-pr-review/scripts/*.py \
  .agents/skills/update-dedupe/scripts/*.py
```

---

## 本地 Spec 开发流程

### 适用场景

- 不需要配置 GitHub Actions Secrets（`AGENT_API_KEY`、`AGENT_MODEL`）
- 个人开发、小型项目、或暂不需要云端 AI 自动化
- 想要完整的 spec-driven 开发体验，但全手动操作

此流程只需要 `git` + Python 标准库，不依赖 `gh` CLI 或 GitHub API。

### 流程概览

```mermaid
flowchart LR
    A[create-issue] --> B[new-spec.sh]
    B --> C[编写 Spec]
    C --> D[git-branch]
    D --> E[实现功能]
    E --> F[verify-impl.sh]
    F --> G[git-commit]
    G --> H[create-pr]
    H --> I[审核合并]
    I --> J[archive-spec.sh]
```

### 详细步骤

| 步骤 | 操作 | 命令/Skill | 输出 |
|------|------|------------|------|
| 1. 创建 Issue | OpenCode skill | `$create-issue` | GitHub Issue #N |
| 2. 创建 Spec 模板 | 本地脚本 | `./scripts/new-spec.sh N` | `specs/issue-N/product.md` + `tech.md` |
| 3. 编写 Spec | 手动编辑 | 编辑器 | 填充 product.md 和 tech.md 内容 |
| 4. 创建开发分支 | OpenCode skill | `$git-branch #N` | `feat/xxx-N` 或 `spec/xxx-N` |
| 5. 实现功能 | 手动开发 | — | 代码变更 |
| 6. 验证实现 | 本地脚本 | `./scripts/verify-impl.sh N` | 验证报告（比对 spec vs diff） |
| 7. 提交代码 | OpenCode skill | `$git-commit` | Git commit（含 SNXXX 前缀） |
| 8. 推送分支 | OpenCode skill | `$git-push` | 推送到 remote |
| 9. 创建 PR | OpenCode skill | `$create-pr` | GitHub PR |
| 10. 归档 Spec | 本地脚本 | `./scripts/archive-spec.sh N implemented PR号` | 更新 spec 状态为 `implemented` |

---

### 脚本详解

#### new-spec.sh — 创建 Spec 模板

**用法：**

```bash
./scripts/new-spec.sh <issue-number> [title]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `issue-number` | ✅ | GitHub Issue 编号 |
| `title` | 可选 | Spec 标题（省略时从 `gh issue view` 自动获取） |

**输出：**

```
specs/issue-<N>/product.md    # Product Spec（含 YAML frontmatter）
specs/issue-<N>/tech.md       # Tech Spec
```

**product.md 模板结构：**

```markdown
---
status: active
issue: <N>
created_at: <date>
---

# Product Spec: <title>

## 1. Summary
## 2. Problem
## 3. Goals
## 4. Non-goals
## 5. Figma / design references
## 6. User experience
## 7. Success criteria        # ← 勾选验收标准
## 8. Validation
## 9. Open questions
```

**示例：**

```bash
# 从 Issue #42 创建 Spec 模板
./scripts/new-spec.sh 42

# 指定标题
./scripts/new-spec.sh 42 "Add OAuth2 authentication"
```

---

#### verify-impl.sh — 验证实现与 Spec 对齐

**用法：**

```bash
./scripts/verify-impl.sh <issue-number> [--base <ref>]
```

**参数：**

| 参数 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `issue-number` | ✅ | — | Issue 编号 |
| `--base` | 可选 | `main` | Git diff 的 base 分支 |

**功能：**

1. 读取 `specs/issue-<N>/product.md` 的 Section 7（验收标准）
2. 读取 `specs/issue-<N>/tech.md` 的 Section 4（预期变更文件）
3. 执行 `git diff <base>...HEAD` 获取实际变更
4. 输出验证报告，包含：
   - 验收标准清单（需手动勾选）
   - 预期文件 vs 实际变更文件对比
   - Diff 统计

**输出示例：**

```markdown
# Implementation Verification Report

**Issue:** #42 — Add OAuth2 authentication

---

## 📋 Acceptance Criteria

- [ ] #1: User can login via Google OAuth
- [ ] #2: Session token expires after 24 hours

> ⚠️  Mark each checkbox after manual verification.

---

## 📄 File Changes

### ✅ Matched (expected in tech spec, found in diff)
- `src/auth/oauth.ts`

### ❌ Not in diff (expected in tech spec, not found)
- `src/utils/token.ts`

---

## 📊 Diff Summary

 src/auth/oauth.ts | 45 +++++++
 1 file changed, 45 insertions(+)
```

---

#### archive-spec.sh — 归档 Spec 状态

**用法：**

```bash
./scripts/archive-spec.sh <issue-number> <status> [value]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `issue-number` | ✅ | Issue 编号 |
| `status` | ✅ | `implemented` 或 `deprecated` |
| `value` | 可选 | `implemented` 时为 PR 编号；`deprecated` 时为原因 |

**状态类型：**

| 状态 | 说明 | 使用场景 |
|------|------|----------|
| `active` | 进行中 | 新建 spec 默认状态 |
| `implemented` | 已实现 | PR 合并后归档 |
| `deprecated` | 已弃用 | 功能取消或不再需要 |

**更新内容：**

脚本会更新 `specs/issue-<N>/product.md` 的 YAML frontmatter：

```yaml
---
status: implemented           # 或 deprecated
issue: 42
created_at: 2024-01-15
implemented_at: 2024-01-20    # 新增
implementation_pr: 123        # 新增（PR 编号）
---
```

**示例：**

```bash
# 标记为已实现，关联 PR #123
./scripts/archive-spec.sh 42 implemented 123

# 标记为已弃用，填写原因
./scripts/archive-spec.sh 42 deprecated "Feature cancelled by stakeholder"
```

---

### 与 GitHub 协作流对比

| 操作 | 本地流程（无 Actions） | GitHub 协作流（有 Actions） |
|------|------------------------|-----------------------------|
| 创建 Issue | `$create-issue` | `$create-issue` |
| 创建 Spec 模板 | 手动 `./scripts/new-spec.sh` | **自动**触发（添加 `ready-to-spec` 标签） |
| 编写 Spec 内容 | 手动编辑 | **AI 自动**生成 product.md + tech.md |
| 创建开发分支 | `$git-branch` | **自动**触发（添加 `plan-approved` 标签） |
| 实现功能 | 手动开发 | **AI 自动**实现代码 |
| 验证实现 | `./scripts/verify-impl.sh` | **自动**运行 `verify-impl-against-spec.yml` |
| 提交/推送 | `$git-commit` + `$git-push` | 自动提交到实现分支 |
| 创建 PR | `$create-pr` | **自动**创建实现 PR |
| 归档 Spec | `./scripts/archive-spec.sh` | **自动**触发（PR 合并） |

**关键差异：**

- 本地流程：所有步骤手动执行，适合需要完全控制的场景
- GitHub 流：Spec 生成、实现、验证、归档全自动，适合团队协作和大规模使用

---

### 脚本依赖

| 脚本 | 依赖 |
|------|------|
| `new-spec.sh` | `bash`、`git`、`gh`（可选，用于自动获取标题） |
| `verify-impl.sh` | `python3`、`git` |
| `archive-spec.sh` | `python3` |

**无需配置：**

- GitHub Secrets（`AGENT_API_KEY`、`AGENT_MODEL`）
- GitHub Actions 工作流
- OpenCode API Key（仅本地 skills 需要）

---

### 典型场景示例

#### 场景 1：个人开发新功能

```bash
# 1. 创建 Issue
$create-issue          # 输入：Add user profile page

# 2. 创建 Spec 模板
./scripts/new-spec.sh 42

# 3. 编写 Spec（手动编辑）
vim specs/issue-42/product.md
vim specs/issue-42/tech.md

# 4. 创建分支
$git-branch #42        # 输出：feat/user-profile-42

# 5. 实现功能
# ... 开发代码 ...

# 6. 验证实现
./scripts/verify-impl.sh 42

# 7. 提交
$git-commit            # 输出：SN001: feat(profile): add user profile page

# 8. 推送
$git-push

# 9. 创建 PR
$create-pr

# 10. PR 合并后归档
./scripts/archive-spec.sh 42 implemented 123
```

#### 场景 2：团队协作（混合模式）

```bash
# 本地创建 Issue 和 Spec 模板
$create-issue
./scripts/new-spec.sh 43

# 团队成员协作编写 Spec
# Push spec 分支，团队审核 product.md + tech.md

# 审核通过后，决定是否切换到 GitHub 自动化流程：
# - 添加 `ready-to-spec` 标签 → 触发 Actions 自动实现
# - 或继续本地手动实现
```

---

> **提示**：本地流程与 GitHub 协作流可以随时切换。添加 `ready-to-spec` 标签是切换点——此时若已配置 Actions Secrets，将触发自动化流程。
