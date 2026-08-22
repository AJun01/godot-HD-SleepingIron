class_name PlayerAnimator
extends Node3D
## Composable animation machine (idle/run/jump/fall/land plus the seven combat
## states) that reads the player's physics state and drives a billboarded
## AnimatedSprite3D. Combat states are one-shots started by play_combat_state and
## held until the animation finishes; the four attack states also track a
## hit-window phase (wind_up/active/recovery) each frame. A preview mode
## (play_preview/stop_preview) forces one of the 12 SpriteFrames animations past
## the physics-derived mapping, for the arena animation-preview zone. One-way
## dependency: the animator reads the player; the player never references the
## animator (design.md). flip_h mirrors the right-facing sheet; the separate
## left-facing sheet is never used.

## Emitted when the active state changes (physics mapping, preview, or combat).
signal state_changed(state: StringName)

## Emitted when the hit-window phase changes while tracking an attack state.
signal phase_changed(state: StringName, phase: StringName)

const STATE_IDLE: StringName = &"idle"
const STATE_RUN: StringName = &"run"
const STATE_JUMP: StringName = &"jump"
const STATE_FALL: StringName = &"fall"
const STATE_LAND: StringName = &"land"
const STATE_ATTACK_1: StringName = &"attack_1"
const STATE_ATTACK_2: StringName = &"attack_2"
const STATE_ATTACK_3: StringName = &"attack_3"
const STATE_ATTACK_AIR: StringName = &"attack_air"
const STATE_HIT: StringName = &"hit"
const STATE_DODGE: StringName = &"dodge"
const STATE_DEATH: StringName = &"death"

## Hit-window phases; PHASE_NONE marks states with no hit window (physics
## states plus dodge/hit/death).
const PHASE_NONE: StringName = &"none"
const PHASE_WIND_UP: StringName = &"wind_up"
const PHASE_ACTIVE: StringName = &"active"
const PHASE_RECOVERY: StringName = &"recovery"

## Combat tunables + per-attack HitWindow references, preloaded like player.gd's
## PLAYER_CONFIG so phase tracking works before the scene-wiring task.
const COMBAT_CONFIG: CombatConfig = preload("res://resources/combat_config.tres")

## Player whose physics state drives the animation. Wired in the scene via
## @export dependency injection (AGENTS.md rule #2).
@export var player: Player

## Fallback path resolved in _ready when the scene-serialized Node reference did
## not resolve (same defensive path-resolution fallback).
@export var player_path: NodePath = NodePath("..")

## AnimatedSprite3D this component drives.
@export var sprite: AnimatedSprite3D

## Fallback path for the sprite, mirroring player_path.
@export var sprite_path: NodePath = NodePath("../AnimatedSprite3D")

## Downward velocity (m/s) below which the animator switches from jump to fall
## while airborne. Hysteresis threshold: near the jump apex velocity.y
## oscillates around zero, so switching at exactly 0.0 flaps jump<->fall every
## frame; this negative threshold keeps "jump" until the body is truly
## descending.
@export var jump_fall_threshold: float = -0.5

var _current_state: StringName = STATE_IDLE
## Current hit-window phase; PHASE_NONE unless an attack state is active.
var _current_phase: StringName = PHASE_NONE
var _land_pending: bool = false
## Forced animation while previewing; empty means preview mode is off.
var _preview_animation: StringName = &""


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
	# Preview mode bypasses the physics-derived mapping entirely, so a forced
	# animation is never overwritten by the next frame's state computation.
	if not _preview_animation.is_empty():
		return
	# Hold one-shot states (land, combat) until they finish before remapping:
	# land never snaps back to idle after a single frame, and combat states are
	# never remapped by the physics-derived mapping.
	if _current_state != STATE_LAND and not _is_combat_state(_current_state):
		_apply_desired_state()
	# Recompute the hit-window phase every frame so phase_changed stays in sync
	# even after a combat one-shot completes back to idle.
	_update_phase()


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
	# Hysteresis on the jump->fall edge: once JUMP, hold JUMP until velocity.y
	# drops below jump_fall_threshold, so apex oscillation around zero does not
	# flap between jump and fall every frame.
	if _current_state == STATE_JUMP and player.velocity.y < jump_fall_threshold:
		return STATE_FALL
	if _current_state == STATE_JUMP or player.velocity.y > 0.0:
		return STATE_JUMP
	return STATE_FALL


func _apply_state(state: StringName) -> void:
	_current_state = state
	sprite.animation = state
	sprite.play()
	state_changed.emit(state)


func play_preview(animation: StringName) -> void:
	_preview_animation = animation
	_apply_state(animation)


func stop_preview() -> void:
	# Resuming is a no-op unless a preview was active, so an unrelated stop
	# (e.g. a leave signal) never snaps a running animation back to idle.
	if _preview_animation.is_empty():
		return
	_preview_animation = &""
	_land_pending = false
	_apply_state(STATE_IDLE)


func _on_player_landed() -> void:
	_land_pending = true


func _on_animation_finished() -> void:
	# A finished one-shot preview must hold its last frame rather than snap back
	# to idle; land and combat one-shots complete here instead.
	if not _preview_animation.is_empty():
		return
	# Land and combat one-shots are held until completion; return to idle and let
	# the next frame's mapping switch to run if the player is already moving.
	if _current_state == STATE_LAND or _is_combat_state(_current_state):
		_apply_state(STATE_IDLE)


func play_combat_state(state: StringName) -> void:
	# Ignore non-combat names: this entry point starts combat one-shots only
	# (physics states come from _desired_state, previews from play_preview).
	if not _is_combat_state(state):
		return
	_apply_state(state)


func get_state() -> StringName:
	return _current_state


func get_phase() -> StringName:
	return _current_phase


func get_frame_progress() -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.0
	var frame_count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	# A one-frame animation has no meaningful progress span.
	if frame_count <= 1:
		return 0.0
	return float(sprite.frame) / float(frame_count - 1)


func is_cancel_window_open() -> bool:
	# Cancel applies only once an attack reaches recovery, so a combo step can be
	# cut short after the threshold fraction of recovery has elapsed.
	if _current_phase != PHASE_RECOVERY:
		return false
	var window: HitWindow = _hit_window_for(_current_state)
	if window == null or sprite == null or sprite.sprite_frames == null:
		return false
	var frame_count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	if frame_count <= 1:
		return false
	# Recovery spans frames (end_frame, last_frame]; when the active window runs
	# to the final frame there is no recovery, so no cancel window.
	var recovery_total: int = frame_count - 1 - window.end_frame
	if recovery_total <= 0:
		return false
	var recovery_progress: float = (
		float(sprite.frame - window.end_frame) / float(recovery_total)
	)
	return recovery_progress >= COMBAT_CONFIG.cancel_recovery_threshold


func _is_combat_state(state: StringName) -> bool:
	return (
		state == STATE_ATTACK_1
		or state == STATE_ATTACK_2
		or state == STATE_ATTACK_3
		or state == STATE_ATTACK_AIR
		or state == STATE_HIT
		or state == STATE_DODGE
		or state == STATE_DEATH
	)


func _update_phase() -> void:
	var phase: StringName = _compute_phase(_current_state)
	if phase == _current_phase:
		return
	_current_phase = phase
	phase_changed.emit(_current_state, phase)


func _compute_phase(state: StringName) -> StringName:
	var window: HitWindow = _hit_window_for(state)
	# A missing window (dodge/hit/death/physics states) or an unavailable sprite
	# has no hit-window information, so degrade to PHASE_NONE rather than guess.
	if window == null or sprite == null:
		return PHASE_NONE
	var frame: int = sprite.frame
	if frame < window.start_frame:
		return PHASE_WIND_UP
	if frame <= window.end_frame:
		return PHASE_ACTIVE
	return PHASE_RECOVERY


func _hit_window_for(state: StringName) -> HitWindow:
	match state:
		STATE_ATTACK_1:
			return COMBAT_CONFIG.attack_1_window
		STATE_ATTACK_2:
			return COMBAT_CONFIG.attack_2_window
		STATE_ATTACK_3:
			return COMBAT_CONFIG.attack_3_window
		STATE_ATTACK_AIR:
			return COMBAT_CONFIG.attack_air_window
		_:
			return null
