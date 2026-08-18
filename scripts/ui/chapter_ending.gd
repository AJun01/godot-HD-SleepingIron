extends Control
## Ending placeholder screen (design.md "Ending screen"). Shown after the final
## trio beat; holds the "Chapter 1 DEMO complete" message for a short beat, then
## returns to the main menu through GameFlow — the only progression entry
## (AGENTS.md Architecture law: scenes never advance themselves).

## Seconds the message stays on screen before the automatic return.
@export var return_delay: float = 3.0


func _ready() -> void:
	get_tree().create_timer(return_delay).timeout.connect(_on_return_timeout)


func _on_return_timeout() -> void:
	GameFlow.request_quit_to_menu()
