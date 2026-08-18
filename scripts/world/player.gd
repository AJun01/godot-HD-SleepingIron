extends CharacterBody3D
## Billboarded player component (AGENTS.md HD-2D invariants: 2D sprite in a lit
## 3D world). Reads 8-direction input from the InputMap move actions and applies
## it on the XZ floor plane. Tunables come from PlayerConfig; gravity is a
## per-body @export so the player settles onto the ground via physics.

const PLAYER_CONFIG: PlayerConfig = preload("res://resources/player_config.tres")

## Downward acceleration applied every physics frame (units/second^2).
@export var gravity: float = 20.0


func _physics_process(delta: float) -> void:
	var direction: Vector3 = _read_input_direction()
	_apply_horizontal_velocity(direction, delta)
	velocity.y -= gravity * delta
	move_and_slide()


func _read_input_direction() -> Vector3:
	# While a dialogue is open, report zero input so friction brings the body to
	# rest and the player cannot walk away mid-beat (design.md movement block).
	if DialogueService.is_open():
		return Vector3.ZERO
	var input_2d: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Map screen up/down to world depth so "up" walks away from the camera.
	return Vector3(input_2d.x, 0.0, input_2d.y)


func _apply_horizontal_velocity(direction: Vector3, delta: float) -> void:
	var horizontal: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var target: Vector3 = direction * PLAYER_CONFIG.move_speed
	if direction.length_squared() > 0.0:
		horizontal = horizontal.move_toward(target, PLAYER_CONFIG.acceleration * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, PLAYER_CONFIG.friction * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
