extends Node3D
## Chapter world controller. Owns only the input escape hatch: ui_cancel asks
## GameFlow to return to the menu. Progression stays owned by GameFlow
## (AGENTS.md Architecture law: scenes never advance themselves).


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameFlow.request_quit_to_menu()
