extends Camera3D
## Follow component: keeps this camera at a fixed offset from an @export target
## with framerate-independent smoothing. A separate component (rather than a
## child of the player) so later tasks can swap in bounds/cutscene behaviour.

## Node the camera tracks. Wired in the scene via @export dependency injection.
@export var target: Node3D

## Camera position relative to the target, in world space.
@export var offset: Vector3 = Vector3(0.0, 12.0, 8.0)

## Follow speed; higher values track more tightly (per-second exponential rate).
@export var follow_speed: float = 6.0


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired: Vector3 = target.global_position + offset
	# Exponential smoothing makes the follow framerate-independent.
	var weight: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)
	look_at(target.global_position, Vector3.UP)
