extends Area3D
## Walk-into-zone trigger for stages with no required NPC (design.md: the
## field-road stage). When the player enters, it asks GameFlow to advance,
## guarded against an in-flight transition.

## Bit value of the interaction layer (project.godot [layer_names] layer 3).
const INTERACTION_LAYER_BIT: int = 1 << 2

## Bit value of the player layer (project.godot [layer_names] layer 2); the
## only layer this area is allowed to detect.
const PLAYER_LAYER_BIT: int = 1 << 1


func _ready() -> void:
	collision_layer = INTERACTION_LAYER_BIT
	collision_mask = PLAYER_LAYER_BIT
	body_entered.connect(_on_body_entered)


func _on_body_entered(_body: Node3D) -> void:
	# Defer the advance so the scene change it triggers never mutates the tree
	# from inside the physics body signal callback (AGENTS.md rule #5).
	call_deferred("_request_advance")


func _request_advance() -> void:
	if SceneRouter.is_transitioning():
		return
	GameFlow.request_advance_stage()
