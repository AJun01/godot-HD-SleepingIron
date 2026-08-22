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

var _jump_buffer_timer: float = 0.0
var _jump_cut_applied: bool = false
var _was_on_floor: bool = true


func _physics_process(delta: float) -> void:
	var direction: Vector2 = _read_movement_input()
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


func _apply_horizontal_velocity(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		var target: Vector2 = direction * PLAYER_CONFIG.move_speed
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
