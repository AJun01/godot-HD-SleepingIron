extends Area3D
## UI/HUD zone trigger (design.md UiHudTrigger). A small Area3D on the
## interaction layer (3) that detects the player (mask 2). MODE_HEALTH shows the
## ObjectiveHud test health bar on body_entered and hides it on body_exited;
## MODE_DIALOGUE plays the hub_test dialogue through DialogueService on
## body_entered, guarded by is_open() so a re-entry while the box is open is a
## no-op. Node creation from these signal callbacks is deferred inside
## ObjectiveHud (AGENTS.md GDScript rule #5).

const MODE_HEALTH: StringName = &"health"
const MODE_DIALOGUE: StringName = &"dialogue"

## Which smoke test this pad drives.
@export var mode: StringName = MODE_HEALTH

## Health-bar max/current for MODE_HEALTH; 100/72 render the unchanged smoke bar.
@export var test_health_max: float = 100.0
@export var test_health_value: float = 72.0

## Dialogue beat played in MODE_DIALOGUE. Wired in the scene to hub_test.tres.
@export var dialogue: DialogueData


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node3D) -> void:
	if mode == MODE_HEALTH:
		ObjectiveHud.show_test_health_bar(test_health_max, test_health_value)
		return
	_play_dialogue()


func _on_body_exited(_body: Node3D) -> void:
	if mode == MODE_HEALTH:
		ObjectiveHud.hide_test_health_bar()


func _play_dialogue() -> void:
	# Re-entering while the box is already open must not restart the run.
	if DialogueService.is_open():
		return
	DialogueService.play(dialogue)
