extends Area3D
## Save/load trigger pad (design.md SaveLoadTrigger). A small Area3D on the
## interaction layer (3) that detects the player (mask 2). save_mode=true saves
## the player's position + facing through SaveService; false restores them. The
## restore mutates the player's transform and facing from a physics signal
## callback, so it is deferred (AGENTS.md GDScript rule #5).

## true = save pad, false = restore pad.
@export var save_mode: bool = true

## Path to the Player, resolved defensively like side_view_camera.gd target_path.
@export var player_path: NodePath = NodePath("../../../Player")

var _player: Player


func _ready() -> void:
	_resolve_player()
	body_entered.connect(_on_body_entered)


func _resolve_player() -> void:
	if player_path.is_empty():
		return
	var resolved: Node = get_node_or_null(player_path)
	if resolved is Player:
		_player = resolved


func _on_body_entered(body: Node3D) -> void:
	# Fall back to the entering body when the exported path did not resolve.
	if _player == null and body is Player:
		_player = body
	if _player == null:
		return
	if save_mode:
		_save()
	else:
		_restore.call_deferred()


func _save() -> void:
	SaveService.save_player_state(_player.global_position, _player.facing)


func _restore() -> void:
	var state: Dictionary = SaveService.load_player_state()
	if state.is_empty() or _player == null:
		return
	_player.global_position = state[SaveService.POSITION_KEY] as Vector3
	_player.facing = int(state[SaveService.FACING_KEY])
