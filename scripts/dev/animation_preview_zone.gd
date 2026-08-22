extends Node3D
## Animation-preview zone controller (design.md AnimationPreviewZone). A small
## composable Node3D that drives the player's animator in preview mode: the
## "next animation" pad cycles the 12 player SpriteFrames animations (wrapping)
## and the "flip facing" pad mirrors the player's facing. The current animation
## name is written to a billboarded status Label3D. The pads are plain Area3D
## children on the interaction layer (3) detecting the player (mask 2); all
## animator/sprite mutations from body_entered are deferred (AGENTS.md rule 5).
## A wider zone-boundary Area3D stops the preview when the player leaves, so the
## physics-driven mapping resumes outside the zone.

## Animation names in map order (docs/character-sprite-mapping.md §4). The
## SpriteFrames API returns names in hash order, so the documented order is kept
## here for a predictable preview cycle.
const ANIMATIONS: Array[StringName] = [
	&"idle",
	&"run",
	&"jump",
	&"fall",
	&"land",
	&"attack_1",
	&"attack_2",
	&"attack_3",
	&"attack_air",
	&"hit",
	&"dodge",
	&"death",
]

## Player whose facing the flip pad toggles. Wired via @export DI.
@export var player: Player

## Fallback path resolved in _ready when the scene-serialized reference did not
## resolve (same defensive path-resolution fallback as side_view_camera.gd).
@export var player_path: NodePath = NodePath("../../Player")

## Animator the preview drives.
@export var animator: PlayerAnimator

## Fallback path for the animator, mirroring player_path.
@export var animator_path: NodePath = NodePath("../../Player/Animator")

## Status Label3D that shows the current preview animation name.
@export var status_label: Label3D

## Fallback path for the status label.
@export var status_label_path: NodePath = NodePath("StatusLabel")

## Path to the "next animation" pad (Area3D, interaction layer 3 / mask 2).
@export var next_anim_pad_path: NodePath = NodePath("NextAnimPad")

## Path to the "flip facing" pad (Area3D, interaction layer 3 / mask 2).
@export var flip_facing_pad_path: NodePath = NodePath("FlipFacingPad")

## Path to the zone-boundary Area3D whose body_exited stops the preview.
@export var zone_boundary_path: NodePath = NodePath("ZoneBoundary")

var _index: int = 0


func _ready() -> void:
	_resolve_references()
	_connect_pads()
	_update_status()


func _resolve_references() -> void:
	if player == null and not player_path.is_empty():
		var resolved_player: Node = get_node_or_null(player_path)
		if resolved_player is Player:
			player = resolved_player
	if animator == null and not animator_path.is_empty():
		var resolved_animator: Node = get_node_or_null(animator_path)
		if resolved_animator is PlayerAnimator:
			animator = resolved_animator
	if status_label == null and not status_label_path.is_empty():
		var resolved_label: Node = get_node_or_null(status_label_path)
		if resolved_label is Label3D:
			status_label = resolved_label


func _connect_pads() -> void:
	var next_pad: Area3D = _resolve_area(next_anim_pad_path)
	if next_pad != null:
		next_pad.body_entered.connect(_on_next_anim_pad_entered)
	var flip_pad: Area3D = _resolve_area(flip_facing_pad_path)
	if flip_pad != null:
		flip_pad.body_entered.connect(_on_flip_facing_pad_entered)
	var boundary: Area3D = _resolve_area(zone_boundary_path)
	if boundary != null:
		boundary.body_exited.connect(_on_zone_exited)


func _resolve_area(area_path: NodePath) -> Area3D:
	if area_path.is_empty():
		return null
	var resolved: Node = get_node_or_null(area_path)
	if resolved is Area3D:
		return resolved
	return null


func _on_next_anim_pad_entered(_body: Node3D) -> void:
	_step.call_deferred(1)


func _on_flip_facing_pad_entered(_body: Node3D) -> void:
	_flip_facing.call_deferred()


func _on_zone_exited(_body: Node3D) -> void:
	_stop_preview.call_deferred()


func _step(delta: int) -> void:
	_index = posmod(_index + delta, ANIMATIONS.size())
	if animator != null:
		animator.play_preview(ANIMATIONS[_index])
	_update_status()


func _flip_facing() -> void:
	if player == null:
		return
	player.facing = -player.facing


func _stop_preview() -> void:
	if animator != null:
		animator.stop_preview()


func _update_status() -> void:
	if status_label == null:
		return
	status_label.text = String(ANIMATIONS[_index])
