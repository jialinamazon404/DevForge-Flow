# DevForge-Flow 开发场景工作流

## 概述

根据任务复杂度选择对应流程。核心原则：**简单任务不绕路，复杂任务不跳步**。

```
判断标准：你心里已经想好怎么改了 → 走场景一
          你还需要想怎么做 → 走场景二
```

---

## 场景一：修 Bug / 改小功能（轻量快速）

适合改文案、修样式、修逻辑 bug、加小按钮等改动明确的场景。

### 快速路径（最轻量，适合 5 分钟改动）

```text
你描述问题
  → OpenCode 直接改代码
  → $git-commit（提交）
  → $git-push（推送）
  → $create-pr（提 PR）
  → 自己 review → 合并
```

**不创建 Issue、不建分支、不写 spec**。一句话需求直接改完提 PR。

### 规范路径（推荐，适合大多数情况）

```text
你描述问题
  → $create-issue（创建 Issue）
  → $git-branch（建分支，自动关联 Issue）
  → OpenCode 改代码
  → $git-commit
  → $git-push
  → $create-pr
  → 自己 review → 合并
```

**产出物**：Issue → 分支 → Commit → PR

### 场景选择

| 情况 | 推荐路径 |
|------|---------|
| 改文案、修样式 | 快速路径 |
| 修逻辑 bug | 规范路径 |
| 加小按钮/小字段 | 规范路径 |
| 重构变量名 | 快速路径 |
| 改配置 | 快速路径 |

---

## 场景二：开发复杂功能（全流程）

适合新页面、新模块、重构子系统、涉及多人协作的功能。

### 流程总览

```text
 Phase 1         Phase 2          Phase 3          Phase 4
───────    ───────────────    ───────────────    ─────────────
 需求             Spec             实现              完成
                   
$create-issue → $write-product-spec → $git-branch → 自己 review
                $write-tech-spec   → 开发代码     → 合并
                                    $git-commit
                                    $git-push
                                    $create-pr
```

### Phase 1：需求

```
$create-issue
```

明确功能背景、需求描述、验收标准。产出 Issue，获得 Issue Number（假设 #N）。

---

### Phase 2：Spec

```
$write-product-spec
  → 产出 specs/issue-N/product.md
  → 审核，不满意让 OpenCode 修改

$write-tech-spec
  → 产出 specs/issue-N/tech.md
  → 审核技术方案
```

| 文件 | 内容 | 审核重点 |
|------|------|---------|
| `product.md` | 用户故事、验收标准、设计说明 | 需求是否完整、验收条件是否清晰 |
| `tech.md` | 架构图、数据流、组件树、API 设计 | 方案是否可行、是否有遗漏边界情况 |

**Spec 完成后**，你和团队对"做什么"和"怎么做"达成一致，再进入实现阶段。

---

### Phase 3：实现

```text
$git-branch feat/xxx-N
  → 创建分支，自动关联 Issue

按 spec 开发代码
  → 可让 OpenCode 协助实现

$git-commit
  → 规范提交

$git-push
  → 推送到远端

$create-pr
  → PR 描述引用 spec
```

产出物：分支 → 代码 → Commit → PR（含 spec 引用）

---

### Phase 4：完成

```text
自己 review PR 内容
确认代码与 spec 一致
合并 PR → Issue 自动关闭
```

---

## 对比总结

| 环节 | 场景一（修 Bug / 小功能） | 场景二（复杂功能） |
|------|--------------------------|-------------------|
| Issue | 可选 | 必须 |
| Spec | 不需要 | 必须（product.md + tech.md） |
| 分支 | 可选 / 自动 | 必须 |
| 开发方式 | 直接改 | 按 spec 实现 |
| Commit | 1 次 | 多次原子提交 |
| Review | 自己看 | 自己看 + 可配 AI review |
| 总时长 | 5-30 分钟 | 数小时到数天 |

---

## 相关 Skill 速查

| Skill | 用途 |
|-------|------|
| `$create-issue` | 从对话创建 GitHub Issue |
| `$write-product-spec` | 编写产品 spec（product.md） |
| `$write-tech-spec` | 编写技术 spec（tech.md） |
| `$git-branch` | 根据 Issue 创建规范分支 |
| `$git-commit` | 从真实 diff 整理原子提交 |
| `$git-push` | 安全推送分支 |
| `$create-pr` | 创建或更新 PR |
| `$review-pr-local` | 本地模拟 PR 审查 |
