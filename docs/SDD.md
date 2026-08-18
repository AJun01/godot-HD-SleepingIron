# SDD 开发流程说明（本项目）

> 本项目所有功能开发走 **SDD（Spec-Driven Development，规格驱动开发）** pipeline。
> 核心原则：**没有落盘的规格，就没有代码**。

## 为什么用 SDD

直接"说需求 → 写代码"的模式会在过程中临时发明范围、跳过架构设计，产出的改动没有对照
任何计划审查过。SDD 把生命周期变成磁盘工件（`.spec/<feature-slug>/`）+ 固定的子代理交接
序列——每个阶段都是一个**冷启动**的子代理，只读自己需要的工件，上一阶段的假设无法泄漏
到下一阶段。

## 五阶段流程（`sdd` skill）

```
/sdd <feature 描述>
  ↓
Phase 0  分诊（编排者亲自）   → intake.md     （问清范围、参考文件、架构，≤8 个问题）
Phase 1  初始化 sdd-init      → scope.md      （检查 AGENTS.md，把 intake 转成规格契约）
Phase 2  设计 sdd-tech-lead   → design.md + tasks.index.md + tasks/xxx.md
Phase 3  实现 sdd-developer   → 每个 task 一个子代理、一次 commit
Phase 4  验证 sdd-verifier    → verify.md + 在 PASS 时开 PR（绝不自动合并）
```

- **失败循环**：每个 feature 最多 3 轮修复；修复任务写在 `.spec/<slug>/fixes/`。
- **断点续跑**：按 `.spec/<slug>/` 里已有工件自动定位到对应阶段，已完成任务跳过。
- **轻量流程 `mini-sdd`**：小改动/修 bug 用；规划在编排者上下文内做，只有实现部分
  委派给一个冷启动的 mini-sdd-developer 子代理。

## `.spec/<feature-slug>/` 工件结构

```
intake.md        编排者输出（分诊问答记录）
scope.md         sdd-init 输出（规格契约）
design.md        sdd-tech-lead 输出（技术设计，不含文件清单）
tasks.index.md   有序任务列表
tasks/001-xxx.md 原子任务（含 Implementation log）
verify.md        sdd-verifier 输出（PASS/FAIL）
fixes/           失败循环的修复任务
```

## 本项目（DSH 环境）的适配说明

原始 sdd-flow 面向 Claude Code/Gemini 等客户端，本环境为 DeepSeek Harness，映射关系：

| 原说明 | 本项目（DSH）实际做法 |
|---|---|
| `/sdd <feature>` 斜杠命令 | 在对话中直接说"用 SDD 开发 xxx"或"sdd: <feature>"，编排者加载 `sdd` skill |
| 子代理委派 | 用 DSH 原生 `subagent` 工具；每个 prompt 自包含（绝对路径 + 冷启动上下文） |
| 子代理 prompt 定义 | `.dsh/skills/sdd/references/agents/*.md`（sdd-init / sdd-tech-lead / sdd-developer / sdd-verifier）与 `.dsh/skills/mini-sdd/references/mini-sdd-developer.md` |
| `CLAUDE.md` | 本项目用根目录 `AGENTS.md`（唯一约定源） |
| PR 门禁 | 需要 git + `gh` 已认证；无 gh 时 Verify 阶段降级为本地验证报告，PR 由人工开 |

## 前置条件

1. 根目录存在 `AGENTS.md`（pipeline 法律文件，sdd-init 会检查，缺失即 FAIL）——已由你
   拥有，AI 不创建、不修改。
2. git 仓库（已初始化）；`gh` 若已登录则 Verify 阶段可自动开 PR。

## Godot 专属验证规则（`godot-sdd` skill）

每个 feature 的 Verify 阶段必须从项目根目录执行 headless 验证：

```bash
godot --headless --editor --path . --quit-after 10
godot --headless --path . --quit-after 5 scenes/<main-scene>.tscn
```

输出中出现 `ERROR:`、`SCRIPT ERROR`、`Parse Error`、`Failed loading` 任一项即 FAIL。
涉及美术资产的 feature 额外登记资产不变量（路径/角色/校验方式），见
`.dsh/skills/godot-sdd/SKILL.md`。

## 分工与美术占位符约定

- **AI 只负责代码与工程问题**；最终美术/音频/视觉方向由你（作者）负责。AI 可以产出
  美术规格、风格参考、资产清单，但不产出最终成品美术。
- **凡是要等美术素材的任务，一律不等。** 缺素材时，先用 AI 自己写的简易 **SVG 占位符**
  （纯色块 + 形状 + 文字标注用途）顶上，保证开发不中断。
- 占位符统一放 `assets/placeholders/`，按目标资产命名（如 `placeholder_player_idle.svg`），
  并在该 feature 的资产登记（`docs/sdd/artifacts/<slug>.yml`）里标 `status: placeholder`，
  方便你之后按清单逐一替换成正式素材。
- 替换"占位符 → 正式素材"是独立的后续任务，不作为任何任务的阻塞条件。

## 纪律红线

- 编排者绝不自己写 scope/design/task/生产代码——一律委派子代理。
- 不手工编辑 `.spec/` 内工件；流程中不删除工件目录。
- 一个 task = 一个 commit（conventional commits）。
- 工件语言：英语。与你的对话：中文。
