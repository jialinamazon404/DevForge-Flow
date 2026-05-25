# AICodingFlow Codex → OpenCode Migration Plan

## Summary

将 AICodingFlow 项目从 Codex (`openai/codex-action@v1`) 迁移到 OpenCode (`anomalyco/opencode/github@latest`)。

## Scope

| Item | Change Needed | Effort |
|------|---------------|--------|
| `.agents/skills/*/SKILL.md` (31 files) | **无改动** - frontmatter 格式已兼容 | ✅ Done |
| `.codex/` symlink | 删除（冗余，`.agents` 已被 OpenCode 支持） | Low |
| `.github/workflows/*.yml` (8 files) | 替换 Codex action → OpenCode action | Medium |
| `.github/scripts/*.py` | **无改动** - context 准备和验证逻辑通用 | ✅ Done |
| `install.sh` | 更新注释/说明 | Low |
| `README.md`, `docs/*.md` | 更新文档 | Low |

## Technical Details

### OpenCode GitHub Action 配置

```yaml
- uses: anomalyco/opencode/github@latest
  env:
    ANTHROPIC_API_KEY: ${{ secrets.AGENT_API_KEY }}  # 或其他 provider
  with:
    model: anthropic/claude-sonnet-4-20250514  # 从 AGENT_MODEL var 获取
    prompt: |  # 可选，用于 workflow_dispatch/schedule/issues 事件
      <instructions>
```

### 与 Codex 的差异

| Aspect | Codex | OpenCode |
|--------|-------|----------|
| Action | `openai/codex-action@v1` | `anomalyco/opencode/github@latest` |
| API Key | `openai-api-key` input | `env` 变量 (ANTHROPIC_API_KEY 等) |
| API Endpoint | `responses-api-endpoint` input | 内置 provider 配置 |
| Model | 通过 endpoint 指定 | `model` input (provider/model 格式) |
| Sandbox | 需要 `bubblewrap` 安装 | 无需额外安装 |
| Trigger | 自动从 prompt 提取 | `prompt` input 或 comment 中的 `/oc` |

### Skills 目录兼容性

OpenCode 原生支持以下目录：
- `.opencode/skills/<name>/SKILL.md` (优先)
- `.claude/skills/<name>/SKILL.md`
- `.agents/skills/<name>/SKILL.md` ← **当前使用，无需改动**

YAML frontmatter 要求：
```yaml
---
name: <skill-name>        # 必需，1-64字符，小写字母数字+单连字符
description: <desc>       # 必需，1-1024字符
license: MIT              # 可选
compatibility: opencode   # 可选
metadata: {}              # 可选
---
```

当前 SKILL.md 已符合此格式。

---

## Migration Steps

### Step 1: 删除 `.codex/` symlink 目录

```bash
rm -rf .codex/
```

理由：`.agents/` 已被 OpenCode 原生识别，`.codex/` symlink 冗余。

### Step 2: 更新 Workflow 文件 (8 个)

每个 workflow 需要修改：
1. 移除 `Install Codex sandbox prerequisites` step
2. 移除 `Configure Codex API endpoint` step
3. 替换 Codex action 为 OpenCode action
4. 调整 API key 配置方式

#### 2.1 triage-issue.yml

**Before:**
```yaml
- name: Install Codex sandbox prerequisites
  run: sudo apt-get install -y bubblewrap

- name: Configure Codex API endpoint
  run: ...  # endpoint setup

- uses: openai/codex-action@v1
  with:
    openai-api-key: ${{ secrets.OPENAI_API_KEY }}
    responses-api-endpoint: ${{ steps.codex_endpoint.outputs.url }}
    prompt: |
      Triage the GitHub issue...
```

**After:**
```yaml
- uses: anomalyco/opencode/github@latest
  env:
    ANTHROPIC_API_KEY: ${{ secrets.AGENT_API_KEY }}
  with:
    model: ${{ vars.AGENT_MODEL || 'anthropic/claude-sonnet-4-20250514' }}
    prompt: |
      Triage the GitHub issue from the stable local context files.
      ...
```

#### 2.2 其他 7 个 workflows

同样的模式应用到：
- `create-spec-from-issue.yml`
- `create-implementation-from-issue.yml`
- `review-pr.yml`
- `respond-to-pr-comment.yml`
- `update-pr-review.yml`
- `plan-approved.yml`
- `update-dedupe.yml`

### Step 3: 更新 Secrets/Variables 命名

建议使用更通用的命名：
- `AGENT_API_KEY` (替代 `OPENAI_API_KEY`)
- `AGENT_MODEL` (如 `anthropic/claude-sonnet-4-20250514`)

或者保持兼容：
- 继续使用 `OPENAI_API_KEY`，但通过 OpenCode 的 OpenAI provider
- model: `openai/gpt-4o` 或类似

### Step 4: 更新 install.sh

```bash
# 更新注释，移除 Codex 相关说明
# 保持 .agents/skills 同步逻辑不变
```

### Step 5: 更新文档

- `README.md`: 更新工具说明 Codex → OpenCode
- `docs/*.md`: 同步更新

---

## Workflow 修改模板

### 通用替换模式

```yaml
# === 移除这些 steps ===
- name: Install Codex sandbox prerequisites
  run: sudo apt-get install -y bubblewrap

- name: Configure Codex API endpoint
  ...

# === 替换 Codex action ===
# FROM:
- uses: openai/codex-action@v1
  env:
    GH_TOKEN: ${{ github.token }}
  with:
    openai-api-key: ${{ secrets.OPENAI_API_KEY }}
    responses-api-endpoint: ${{ ... }}
    prompt: |
      ...

# TO:
- uses: anomalyco/opencode/github@latest
  env:
    GH_TOKEN: ${{ github.token }}
    ANTHROPIC_API_KEY: ${{ secrets.AGENT_API_KEY }}
  with:
    model: ${{ vars.AGENT_MODEL || 'anthropic/claude-sonnet-4-20250514' }}
    prompt: |
      ...
```

### Prompt 保持不变

现有的 prompt 结构无需修改，OpenCode 同样能理解：
- 指定 input 文件（如 `triage_context.json`）
- 指定 skill 文件路径（如 `.agents/skills/triage-issue/SKILL.md`）
- 指定 output 文件（如 `triage_result.json`）

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| OpenCode 输出格式可能与 Codex 不同 | 保持 JSON schema 验证脚本，必要时调整 |
| Skill 加载路径可能有差异 | `.agents/skills/` 已验证兼容 |
| API 调用成本可能变化 | 使用相同的 model tier (sonnet-class) |
| GitHub token 权限 | OpenCode action 需要 `permissions: id-token: write` |

---

## Post-Migration Validation

1. 运行 Python 测试套件验证 scripts 仍正常工作
2. 在测试 repo 上手动触发 `workflow_dispatch` 验证流程
3. 检查 issue triage、spec creation、PR review 等端到端流程

---

## Rollback Plan

如遇问题可快速回滚：
```bash
git revert <migration-commit>
# 重新添加 .codex/ symlink
ln -s ../.agents/AGENTS.md .codex/AGENTS.md
ln -s ../.agents/skills .codex/skills
```

---

## Estimated Effort

- Workflow 修改: ~2-3 hours (8 files)
- 文档更新: ~30 minutes
- 测试验证: ~1-2 hours
- **Total: ~4-6 hours**