class_name Player
extends CharacterBody3D
## Side-view player physics (AGENTS.md HD-2D invariants: billboarded sprite in a
## lit 3D world). Lives on the X–Y play plane: horizontal input drives X, gravity
## and jumping act on Y, and Z stays pinned to the play plane. All movement and
## jump-feel tunables come from PlayerConfig; jumping uses a short input buffer
## plus a jump-cut so a tap yields a short hop and a hold yields a full jump
## (design.md ACT feel).

## Emitted once when the body returns to the floor, for the animator (task 002).
signal landed

const PLAYER_CONFIG: PlayerConfig = preload("res://resources/player_config.tres")

## Facing sign driven by the last non-zero horizontal input: +1 right, -1 left.
var facing: int = 1

var _jump_buffer_timer: float = 0.0
var _jump_cut_applied: bool = false
var _was_on_floor: bool = true


func _physics_process(delta: float) -> void:
	var direction_x: float = _read_horizontal_input()
	_update_facing(direction_x)
	_apply_horizontal_velocity(direction_x, delta)
	_apply_gravity(delta)
	_consume_jump_buffer(delta)
	# Constrain motion to the X–Y play plane.
	velocity.z = 0.0
	move_and_slide()
	_detect_landing()


func _unhandled_input(event: InputEvent) -> void:
	# Dialogue owns the input lock: movement is gated in _read_horizontal_input
	# and jump is gated here, so both stay inert mid-beat.
	if DialogueService.is_open():
		return
	if event.is_action_pressed(&"jump") and not event.is_echo():
		_jump_buffer_timer = PLAYER_CONFIG.jump_buffer_time
	elif event.is_action_released(&"jump"):
		_apply_jump_cut()


func _read_horizontal_input() -> float:
	# While a dialogue is open, report zero input so friction brings the body to
	# rest and the player cannot walk away mid-beat (design.md movement block).
	if DialogueService.is_open():
		return 0.0
	return Input.get_axis("move_left", "move_right")


func _apply_horizontal_velocity(direction_x: float, delta: float) -> void:
	if direction_x != 0.0:
		var target_x: float = direction_x * PLAYER_CONFIG.move_speed
		velocity.x = move_toward(velocity.x, target_x, PLAYER_CONFIG.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, PLAYER_CONFIG.friction * delta)


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
