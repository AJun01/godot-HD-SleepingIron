extends Node3D
## Minimal boot entry point. A dedicated boot scene is the configured main scene
## (design.md) so the very first screen change also flows through GameFlow +
## SceneRouter — one uniform progression entry per the Architecture law.


func _ready() -> void:
	GameFlow.start_flow()
