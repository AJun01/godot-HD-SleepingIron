class_name Player
extends CharacterBody3D
## Side-view player physics (AGENTS.md HD-2D invariants: billboarded sprite in a
## lit 3D world). Horizontal input drives X (left/right) and Z (depth via
## move_up/move_down); gravity and jumping act on Y only. All movement and
## jump-feel tunables come from PlayerConfig; jumping uses a short input buffer
## plus a jump-cut so a tap yields a short hop and a hold yields a full jump
## (design.md ACT feel).

## Emitted once when the body returns to the floor, for the animator (task 002).
signal landed

const PLAYER_CONFIG: PlayerConfig = preload("res://resources/player_config.tres")

## Facing sign driven by the last non-zero X input: +1 right, -1 left.
var facing: int = 1

## Combat-set lock: while true, movement input is ignored and horizontal
## velocity decays toward zero (attack_1/2/3, attack_air).
var movement_locked: bool = false

## Combat-set override: while non-zero, this is the horizontal velocity
## (dodge carries its own movement); gravity still runs.
var movement_override: Vector2 = Vector2.ZERO

## RUN tier active: a same-direction double-tap within the window upgraded the
## held direction from walk to run; cleared when movement input returns to zero.
## Public so the animator reads it one-way for walk vs run animation mapping.
var running: bool = false

## Direction of the most recent fresh direction-key press (unit Vector2), used
## to detect a same-direction double-tap.
var _last_dir_key: Vector2 = Vector2.ZERO

## Timestamp (ms) of the most recent fresh direction-key press.
var _last_dir_press_ms: int = 0

var _jump_buffer_timer: float = 0.0
var _jump_cut_applied: bool = false
var _was_on_floor: bool = true


func _physics_process(delta: float) -> void:
	var direction: Vector2 = _read_movement_input()
	# Zero input means the player let go: clear the run tier but keep the last
	# press record so a double-tap survives the release gap between its two
	# taps; the window check in _track_double_tap expires stale records.
	if direction == Vector2.ZERO:
		running = false
	_update_facing(direction.x)
	_apply_horizontal_velocity(direction, delta)
	_apply_gravity(delta)
	_consume_jump_buffer(delta)
	move_and_slide()
	_detect_landing()


func _unhandled_input(event: InputEvent) -> void:
	# Dialogue owns the input lock: movement is gated in _read_movement_input
	# and jump is gated here, so both stay inert mid-beat.
	if DialogueService.is_open():
		return
	_track_double_tap(event)
	if event.is_action_pressed(&"jump") and not event.is_echo():
		_jump_buffer_timer = PLAYER_CONFIG.jump_buffer_time
	elif event.is_action_released(&"jump"):
		_apply_jump_cut()


func _read_movement_input() -> Vector2:
	# While a dialogue is open, report zero input so friction brings the body to
	# rest and the player cannot walk away mid-beat (design.md movement block).
	if DialogueService.is_open():
		return Vector2.ZERO
	var raw: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	# Normalize so diagonal walking is not √2 faster than a cardinal axis.
	return raw.limit_length(1.0)


func _track_double_tap(event: InputEvent) -> void:
	# Echo events are key-repeat, not fresh presses: filtering them prevents a
	# held key from faking a double-tap and silently upgrading walk to run.
	if event.is_echo():
		return
	var dir: Vector2 = _direction_for_event(event)
	if dir == Vector2.ZERO:
		return
	var now_ms: int = Time.get_ticks_msec()
	var window_ms: int = int(PLAYER_CONFIG.double_tap_window * 1000.0)
	# Two fresh presses of the SAME direction within the window arm the RUN tier.
	if dir == _last_dir_key and now_ms - _last_dir_press_ms <= window_ms:
		running = true
	_last_dir_key = dir
	_last_dir_press_ms = now_ms


func _direction_for_event(event: InputEvent) -> Vector2:
	# is_action_pressed ignores releases, so only fresh presses advance the
	# double-tap tracker. move_up is -Z and move_down is +Z, matching the
	# input-to-velocity mapping in _read_movement_input.
	if event.is_action_pressed(&"move_left"):
		return Vector2(-1.0, 0.0)
	if event.is_action_pressed(&"move_right"):
		return Vector2(1.0, 0.0)
	if event.is_action_pressed(&"move_up"):
		return Vector2(0.0, -1.0)
	if event.is_action_pressed(&"move_down"):
		return Vector2(0.0, 1.0)
	return Vector2.ZERO


func _apply_horizontal_velocity(direction: Vector2, delta: float) -> void:
	# Dodge carries its own displacement: the override wins outright so input and
	# friction never fight the dodge impulse (design.md §6).
	if movement_override != Vector2.ZERO:
		velocity.x = movement_override.x
		velocity.z = movement_override.y
		return
	# Attack lock: ignore input and decay horizontal velocity toward zero, so an
	# attack slides to a smooth stop instead of snapping (design.md §6).
	if movement_locked:
		velocity.x = move_toward(velocity.x, 0.0, PLAYER_CONFIG.friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, PLAYER_CONFIG.friction * delta)
		return
	if direction != Vector2.ZERO:
		# Run tier when a same-direction double-tap armed it; otherwise walk.
		var speed: float = PLAYER_CONFIG.move_speed if running else PLAYER_CONFIG.walk_speed
		var target: Vector2 = direction * speed
		velocity.x = move_toward(velocity.x, target.x, PLAYER_CONFIG.acceleration * delta)
		velocity.z = move_toward(velocity.z, target.y, PLAYER_CONFIG.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, PLAYER_CONFIG.friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, PLAYER_CONFIG.friction * delta)


func _apply_gravity(delta: float) -> void:
	# Only pull while airborne; grounded frames keep velocity.y flat so
	# move_and_slide stays snapped to the floor.
	if not is_on_floor():
		velocity.y -= PLAYER_CONFIG.gravity * delta


func _consume_jump_buffer(delta: float) -> void:
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	# is_on_floor() reflects the previous move_and_slide, so a press buffered
	# just before touchdown fires on the frame after landing.
	if is_on_floor() and _jump_buffer_timer > 0.0:
		velocity.y = PLAYER_CONFIG.jump_velocity
		_jump_buffer_timer = 0.0
		_jump_cut_applied = false


func _apply_jump_cut() -> void:
	# Cut only while ascending (velocity.y > 0) and once per jump, so a quick tap
	# yields a shorter hop than a held jump.
	if _jump_cut_applied or velocity.y <= 0.0:
		return
	velocity.y *= PLAYER_CONFIG.jump_cut_factor
	_jump_cut_applied = true


func _update_facing(direction_x: float) -> void:
	if direction_x > 0.0:
		facing = 1
	elif direction_x < 0.0:
		facing = -1


func _detect_landing() -> void:
	if is_on_floor() and not _was_on_floor:
		landed.emit()
	_was_on_floor = is_on_floor()
