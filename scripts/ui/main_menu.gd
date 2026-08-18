extends Control
## Main menu scene. The only progression triggers are the two buttons, which
## call GameFlow methods (AGENTS.md Architecture law: scenes never advance
## themselves). Keyboard navigation is inherited from Godot focus + ui_* actions;
## focus is grabbed on the primary button so it works without any mouse input.

@onready var _new_game_button: Button = %NewGameButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_new_game_button.pressed.connect(GameFlow.request_new_game)
	_quit_button.pressed.connect(GameFlow.request_quit)
	# Keyboard-first entry point: hand focus to the primary action so arrow keys
	# and Enter reach the buttons before any mouse movement.
	_new_game_button.grab_focus()
