extends Node3D
## Composable five-state animation machine (idle/run/jump/fall/land) that reads
## the player's physics state and drives a billboarded AnimatedSprite3D. One-way
## dependency: the animator reads the player; the player never references the
## animator (design.md). flip_h mirrors the right-facing sheet; the separate
## left-facing sheet is never used.

const STATE_IDLE: StringName = &"idle"
const STATE_RUN: StringName = &"run"
const STATE_JUMP: StringName = &"jump"
const STATE_FALL: StringName = &"fall"
const STATE_LAND: StringName = &"land"

## Player whose physics state drives the animation. Wired in the scene via
## @export dependency injection (AGENTS.md rule #2).
@export var player: Player

## Fallback path resolved in _ready when the scene-serialized Node reference did
## not resolve (same defensive pattern as camera_follow.gd).
@export var player_path: NodePath = NodePath("..")

## AnimatedSprite3D this component drives.
@export var sprite: AnimatedSprite3D

## Fallback path for the sprite, mirroring player_path.
@export var sprite_path: NodePath = NodePath("../AnimatedSprite3D")

var _current_state: StringName = STATE_IDLE
var _land_pending: bool = false


func _ready() -> void:
	_resolve_references()
	if player == null or sprite == null:
		return
	player.landed.connect(_on_player_landed)
	sprite.animation_finished.connect(_on_animation_finished)
	_apply_state(STATE_IDLE)


func _process(_delta: float) -> void:
	if player == null or sprite == null:
		return
	sprite.flip_h = player.facing < 0
	# Hold the one-shot land animation until it finishes before remapping, so a
	# landing never snaps back to idle after a single frame.
	if _current_state == STATE_LAND:
		return
	_apply_desired_state()


func _resolve_references() -> void:
	if player == null and not player_path.is_empty():
		var resolved_player: Node = get_node_or_null(player_path)
		if resolved_player is Player:
			player = resolved_player
	if sprite == null and not sprite_path.is_empty():
		var resolved_sprite: Node = get_node_or_null(sprite_path)
		if resolved_sprite is AnimatedSprite3D:
			sprite = resolved_sprite


func _apply_desired_state() -> void:
	var desired: StringName = _desired_state()
	if desired == _current_state:
		return
	_apply_state(desired)


func _desired_state() -> StringName:
	if player.is_on_floor():
		if _land_pending:
			_land_pending = false
			return STATE_LAND
		if Vector2(player.velocity.x, player.velocity.z) != Vector2.ZERO:
			return STATE_RUN
		return STATE_IDLE
	if player.velocity.y > 0.0:
		return STATE_JUMP
	return STATE_FALL


func _apply_state(state: StringName) -> void:
	_current_state = state
	sprite.animation = state
	sprite.play()


func _on_player_landed() -> void:
	_land_pending = true


func _on_animation_finished() -> void:
	# Land is the only state held until completion; return to idle and let the
	# next frame's mapping switch to run if the player is already moving.
	if _current_state == STATE_LAND:
		_apply_state(STATE_IDLE)
