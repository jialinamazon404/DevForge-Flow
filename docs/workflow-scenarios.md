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
  → $create-issue（创建 Issue，获得 #N）
  → $git-branch（建分支 feat/xxx-N，自动关联 Issue）
  → OpenCode 改代码
  → $git-commit
  → $git-push
  → $create-pr（引用 Issue）
  → 自己 review → 合并
```

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

---

### Phase 1：需求

```
$create-issue
```

明确功能背景、需求描述、验收标准。产出 Issue，获得 Issue Number（假设 #N）。

---

### Phase 2：Spec（核心环节）

Spec 阶段是复杂功能的核心。它的目标是在写任何代码之前，让团队对"做什么"和"怎么做"达成一致。

#### Step 1：写 Product Spec

```
$write-product-spec
```

OpenCode 会做以下事情：

```
① 收集上下文
   ├── 读取 Issue 描述和评论
   ├── 确认目标用户/使用场景
   ├── 识别关键行为和约束
   ├── 梳理已知边界情况
   └── 确认验证方式（测试、截图、视频等）

② 补充信息
   ├── 如果有 UI 改动 → 询问是否有 Figma 设计稿
   ├── 如果有不明确的细节 → 向你提问确认
   └── 没有设计稿就打标注 "Figma: none provided"

③ 产出文件：specs/issue-N/product.md
   └── 结构：
       ├── 1. Summary         — 功能一句话概述
       ├── 2. Problem         — 解决什么用户/产品问题
       ├── 3. Goals           — 必须达成的目标
       ├── 4. Non-goals       — 明确不做的事
       ├── 5. Design refs     — Figma 链接或标注
       ├── 6. User experience — 详细的用户可见行为
       │     包括：默认行为、状态转换、边界情况、空状态、错误状态
       ├── 7. Success criteria— 验收标准（可测试、可观察）
       ├── 8. Validation      — 如何验证
       └── 9. Open questions  — 未决问题
```

**审核**：你阅读 `product.md`，确认需求无误。不满意就让 OpenCode 修改，直到验收标准清晰可测。

#### Step 2：写 Tech Spec

```
$write-tech-spec
```

在 `product.md` 就绪后执行。OpenCode 会做以下事情：

```
① 阅读 Product Spec
   └── 理解"要做什么"，为技术方案锚定目标

② 研究代码库
   ├── 检查现有架构和模式
   ├── 识别涉及的文件、类型、数据流
   ├── 理解当前行为及其不足
   └── 注意依赖关系、约束条件、风险点

③ 产出文件：specs/issue-N/tech.md
   └── 结构：
       ├── 1. Problem          — 技术问题是什么
       ├── 2. Relevant code    — 涉及的核心文件（含行号）
       │    例：src/module.py:42 — 用户流程入口
       │        src/components/button.tsx:10 — 可参考的现有组件
       ├── 3. Current state    — 当前系统如何工作
       ├── 4. Proposed changes — 改动计划（模块、API、数据流）
       ├── 5. End-to-end flow  — 主流程的完整路径
       ├── 6. Risks & mitigations — 风险、兼容性、回滚方案
       ├── 7. Testing          — 测试策略
       └── 8. Follow-ups       — 后续可做的事
```

**审核**：你阅读 `tech.md`，确认技术方案可行、没有遗漏边界情况。

#### Spec 阶段的最终产出

```
specs/issue-N/
  product.md   # 产品需求：行为描述、验收标准、设计说明
  tech.md      # 技术方案：架构、数据流、组件、API、风险
```

**验收标准**：审阅者能通过 `product.md` 回答"这是我们要的行为吗？"，通过 `tech.md` 回答"这是安全合理的实现方式吗？"

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

实现过程中如果发现 spec 需要调整，**同步更新 spec 文件**，保持 spec 与代码一致。

```
spec 和代码在同一个 PR 里一起演进 → 最终一起合并
```

---

### Phase 4：完成

```text
自己 review PR 内容
确认代码与 spec 一致
合并 PR → Issue 自动关闭
```

---

## 全流程视图（含 Spec 内部细节）

```text
$create-issue
  │ Issue #N
  ▼
$write-product-spec
  ├── 收集需求上下文
  ├── 确认 Figma / 设计稿
  ├── 向你提问补充细节
  └── 产出 specs/issue-N/product.md  →  ⭐ 你审核
  │
  ▼  (审核通过)
$write-tech-spec
  ├── 阅读 product.md
  ├── 研究代码库（文件、架构、数据流）
  └── 产出 specs/issue-N/tech.md     →  ⭐ 你审核
  │
  ▼  (审核通过)
$git-branch feat/xxx-N
  │ 分支创建完毕
  ▼
开发代码
  │ 按 spec 实现
  ▼
$git-commit → $git-push → $create-pr
  │ PR 引用 spec + Issue
  ▼
review → 合并 → Issue 自动关闭
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
| `$write-product-spec` | 编写产品 spec（含上下文收集、需求澄清、Figma 确认） |
| `$write-tech-spec` | 编写技术 spec（含代码库研究、架构分析） |
| `$spec-driven-implementation` | Spec 驱动开发全流程编排 |
| `$implement-specs` | 按已审核 spec 实现功能 |
| `$git-branch` | 根据 Issue 创建规范分支 |
| `$git-commit` | 从真实 diff 整理原子提交 |
| `$git-push` | 安全推送分支 |
| `$create-pr` | 创建或更新 PR |
| `$review-pr-local` | 本地模拟 PR 审查 |
