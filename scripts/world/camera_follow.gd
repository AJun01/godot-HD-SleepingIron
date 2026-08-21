extends Camera3D
## Follow component: keeps this camera at a fixed offset from an @export target
## with framerate-independent smoothing. A separate component (rather than a
## child of the player) so later tasks can swap in bounds/cutscene behaviour.

## Node the camera tracks. Wired in the scene via @export dependency injection.
@export var target: Node3D

## Fallback path resolved in _ready when the scene-serialized Node reference did
## not resolve (Godot silently leaves Node-typed exports null in some scene
## load paths). NodePath is a value type, so reading it back always works.
@export var target_path: NodePath = NodePath("../Player")

## Camera position relative to the target, in world space.
@export var offset: Vector3 = Vector3(0.0, 12.0, 8.0)

## Follow speed; higher values track more tightly (per-second exponential rate).
@export var follow_speed: float = 6.0


func _ready() -> void:
	# Defensive resolution: the exported Node reference can come back null after
	# scene instantiation even when the sibling exists; resolve by path instead.
	if target == null and not target_path.is_empty():
		var resolved: Node = get_node_or_null(target_path)
		if resolved is Node3D:
			target = resolved


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired: Vector3 = target.global_position + offset
	# Exponential smoothing makes the follow framerate-independent.
	var weight: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)
	look_at(target.global_position, Vector3.UP)
