extends Area3D
## SFX trigger pad (design.md SfxTrigger). A small Area3D on the interaction
## layer (3) that detects the player (mask 2). On body_entered it plays the
## exported AudioStream through the child AudioStreamPlayer, skipping the play
## while a beep is already sounding so rapid re-entries do not restart it.

## Beep played when the player steps onto this pad. Wired in the scene.
@export var stream: AudioStream

## Path to the child AudioStreamPlayer that voices the beep, resolved
## defensively like save_load_trigger.gd's player_path.
@export var audio_player_path: NodePath = NodePath("AudioStreamPlayer")

var _audio_player: AudioStreamPlayer


func _ready() -> void:
	_resolve_audio_player()
	body_entered.connect(_on_body_entered)


func _resolve_audio_player() -> void:
	if audio_player_path.is_empty():
		return
	var resolved: Node = get_node_or_null(audio_player_path)
	if resolved is AudioStreamPlayer:
		_audio_player = resolved


func _on_body_entered(_body: Node3D) -> void:
	if _audio_player == null or stream == null:
		return
	# Re-entering while the beep is still sounding must not restart it.
	if _audio_player.playing:
		return
	_audio_player.stream = stream
	_audio_player.play()
