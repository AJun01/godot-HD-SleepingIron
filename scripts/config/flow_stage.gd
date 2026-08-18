class_name FlowStage
extends Resource
## One entry in the linear progression. FlowConfig holds these in order; the
## array index IS the flow order.

## Stable identifier GameFlow maps to a state (e.g. &"menu", &"chapter").
@export var id: StringName = &""

## Packed scene path loaded by SceneRouter when this stage is entered.
@export var scene_path: String = ""
