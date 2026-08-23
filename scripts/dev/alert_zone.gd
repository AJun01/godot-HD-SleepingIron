extends Node3D
## Alert-zone controller: flips the player animator between the alert (combat)
## and non-alert (safe-area) animation sets while the player is inside the zone.
## A composable Node3D mirroring animation_preview_zone.gd: the animator is
## injected via @export DI with a node-path fallback, and the zone boundary is an
## Area3D on the interaction layer (3) detecting the player (mask 2). Both mode
## flips from body_entered/body_exited are deferred (AGENTS.md rule 5). One-way
## dependency: the zone writes the animator's alert_mode; nothing reads it back.

## Animator whose alert_mode this zone drives. Wired via @export DI.
@export var animator: PlayerAnimator

## Fallback path resolved in _ready when the scene reference did not resolve.
@export var animator_path: NodePath = NodePath("../../Player/Animator")

## Path to the zone-boundary Area3D (interaction layer 3 / mask 2).
@export var zone_boundary_path: NodePath = NodePath("ZoneBoundary")


func _ready() -> void:
	_resolve_references()
	_connect_boundary()


func _resolve_references() -> void:
	if animator == null and not animator_path.is_empty():
		var resolved_animator: Node = get_node_or_null(animator_path)
		if resolved_animator is PlayerAnimator:
			animator = resolved_animator


func _connect_boundary() -> void:
	var boundary: Area3D = _resolve_area(zone_boundary_path)
	if boundary != null:
		boundary.body_entered.connect(_on_boundary_entered)
		boundary.body_exited.connect(_on_boundary_exited)


func _resolve_area(area_path: NodePath) -> Area3D:
	if area_path.is_empty():
		return null
	var resolved: Node = get_node_or_null(area_path)
	if resolved is Area3D:
		return resolved
	return null


func _on_boundary_entered(_body: Node3D) -> void:
	_set_alert_mode.call_deferred(true)


func _on_boundary_exited(_body: Node3D) -> void:
	_set_alert_mode.call_deferred(false)


func _set_alert_mode(enabled: bool) -> void:
	if animator != null:
		animator.set_alert_mode(enabled)
