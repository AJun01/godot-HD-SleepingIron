extends Area3D
## Composable interaction trigger (AGENTS.md rule #3: composition over
## inheritance). Detects the player via a physics area, then on the interact
## press hands its DialogueData to DialogueService. When
## advance_stage_on_complete is set, it asks GameFlow to advance the flow after
## the dialogue finishes.

## Bit value of the interaction layer (project.godot [layer_names] layer 3);
## trigger areas live here so they never collide with world geometry.
const INTERACTION_LAYER_BIT: int = 1 << 2

## Bit value of the player layer (project.godot [layer_names] layer 2); the
## only layer this area is allowed to detect.
const PLAYER_LAYER_BIT: int = 1 << 1

## Dialogue beat played when this object is interacted with.
@export var dialogue: DialogueData

## When true, request a stage advance once the dialogue finishes.
@export var advance_stage_on_complete: bool = false

var _player_in_range: bool = false


func _ready() -> void:
	collision_layer = INTERACTION_LAYER_BIT
	collision_mask = PLAYER_LAYER_BIT
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node3D) -> void:
	_player_in_range = true


func _on_body_exited(_body: Node3D) -> void:
	_player_in_range = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact") or event.is_echo():
		return
	if not _player_in_range or SceneRouter.is_transitioning() or DialogueService.is_open():
		return
	if dialogue == null:
		return
	# Consume the opening press so the key that opens the dialogue can never
	# also be read as an advance press.
	get_viewport().set_input_as_handled()
	# A forced close (e.g. a scene transition) makes play() return false; advancing
	# then would push the flow forward mid-transition.
	var completed: bool = await DialogueService.play(dialogue)
	if completed and advance_stage_on_complete:
		GameFlow.request_advance_stage()
