# Sleeping Iron HD-2D

> 基于 A.J Liu 原创科幻机甲小说《SLEEPING IRON》改编的 HD-2D 风格游戏（Godot 4.7）。

## 开发环境

| 组件 | 版本/来源 |
|---|---|
| 引擎 | Godot 4.7.1 stable（Homebrew cask：`brew install --cask godot`） |
| 渲染 | Forward Plus，Windows 下 d3d12 |
| 物理 | Jolt Physics |
| 分辨率 | 1920×1080，`viewport` 拉伸 |

打开项目：`godot --path .`（或直接用 Godot 编辑器打开本目录）。

## 开发流程：SDD（Spec-Driven Development）

本项目**强制**走 SDD pipeline——先写规格、再设计、再实现、最后验证，所有产物落盘在
`.spec/<feature-slug>/`。任何功能开发前必须先有 spec，不直接写代码。

详细说明见 [docs/SDD.md](docs/SDD.md)。

- 大功能/架构级改动 → **`sdd`** skill（五阶段全流程）
- 小修复/小重构 → **`mini-sdd`** skill（轻量流程，需你确认）
- 项目约定（代码风格、目录、验证命令）→ [AGENTS.md](AGENTS.md)（pipeline 前置文件，由你拥有）

## 已安装的项目 skills（`.dsh/skills/`）

- **SDD pipeline**（nushey/sdd-flow，MIT）：`sdd`、`mini-sdd`、`mini-sdd-planner`、
  `pr-creation`、`writing-skill`，含 5 个子代理 prompt（init / tech-lead / developer /
  verifier / mini-developer）。
- **Godot 验证**：`godot-sdd`（本项目适配版，Godot headless 验证 + 资产登记）。
- **游戏开发全家桶**（AlterLab GameForge，MIT）：引擎专家 `game-godot-specialist`，
  全生命周期 workflow（`game-start`、`game-gdd-author`、`game-prototype`、`game-sprint-plan`、
  `game-code-review`、`game-playtest`、`game-design-review`、`game-scope-check`、
  `game-brainstorm`、`game-postmortem` 等 20 个），角色专家（`game-narrative-director`、
  `game-art-director`、`game-technical-director`、`game-designer`、`game-audio-director`、
  `game-producer` 等 12 个）。

## 目录结构

```
scenes/          # 场景（world/ui/actors...）
scripts/         # GDScript，autoload 放 scripts/autoload/
assets/          # sprites / textures / audio / fonts / shaders / ui / vfx
addons/          # 第三方插件
docs/            # GDD、模板（docs/templates）、题材包（docs/genre-packs）
docs/source/     # 原作小说《SLEEPING IRON》正文（游戏剧情唯一依据）
.spec/           # SDD 产物（pipeline 自动创建，勿手改）
.dsh/skills/     # 项目级 skills（已入版本控制）
```

## 约定速览

- GDScript 全静态类型、信号解耦、组合优于继承、数值一律 `@export`/Resource。
- 每个功能完成前必须跑通 headless 验证（见 AGENTS.md）。
- 一个 task = 一个 commit；PR 由 verifier 创建，人工合并。
- 剧情以 `docs/source/正文.md` 为准，小说未写到的细节先问作者（你），不自行编造设定。
