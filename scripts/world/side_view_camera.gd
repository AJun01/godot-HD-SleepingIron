extends Camera3D
## Side-view follow component: keeps this camera locked to a horizontal-forward
## side view while its X follows an @export target with framerate-independent
## smoothing. Y and Z are pinned (waist-height and behind the play plane), so the
## framing never drifts vertically or in depth. Mirrors camera_follow.gd's target/
## target_path/follow_speed pattern but with side-view semantics (no look_at).

## Node the camera tracks. Wired in the scene via @export dependency injection.
@export var target: Node3D

## Fallback path resolved in _ready when the scene-serialized Node reference did
## not resolve (same defensive pattern as camera_follow.gd).
@export var target_path: NodePath = NodePath("../Player")

## Fixed camera height in world space (waist-height side view).
@export var vertical_offset: float = 1.2

## Fixed camera depth behind the play plane (Z=0), in world space.
@export var z_distance: float = 10.0

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
	# Exponential smoothing makes the X-follow framerate-independent. Y and Z are
	# assigned (not smoothed) so they stay exactly fixed at the side-view offsets.
	var weight: float = 1.0 - exp(-follow_speed * delta)
	var smoothed_x: float = lerpf(global_position.x, target.global_position.x, weight)
	global_position = Vector3(smoothed_x, vertical_offset, z_distance)
	# Rotation is never touched: the camera keeps identity rotation and looks
	# horizontally forward (-Z) rather than top-down at the target.
