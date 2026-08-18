class_name FlowStage
extends Resource
## One entry in the linear progression. FlowConfig holds these in order; the
## array index IS the flow order.

## Stable identifier for this stage (e.g. &"menu", &"chapter_home").
@export var id: StringName = &""

## Progression tag (&"menu" | &"chapter") GameFlow maps to a State. Every chapter
## stage shares the &"chapter" tag, so adding a stage never requires a GameFlow
## code change (AGENTS.md Architecture law: stages extend FlowConfig, never code).
@export var state: StringName = &""

## Objective text shown by the HUD while this stage is active; empty for stages
## with no goal (menu and ending).
@export var objective: String = ""

## Packed scene path loaded by SceneRouter when this stage is entered.
@export var scene_path: String = ""
