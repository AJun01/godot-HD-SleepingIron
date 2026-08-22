extends Node3D
## Combat-range zone controller (design.md §10). A small composable Node3D that
## binds the three arena dummies to a reset pad: stepping on the pad (interaction
## layer 3 / mask 2) restores every dummy to full HP and the billboarded status
## Label3D reports the reset. The dummy mutation from the body_entered signal is
## deferred (AGENTS.md rule 5). Bounded to reset + status conveniences; the
## dummies are injected via @export DI, matching animation_preview_zone.gd.

## Short hint shown while the zone is idle.
const HINT_TEXT: String = "Attack (J) · Pad resets"

## Confirmation shown after the reset pad restores all dummies.
const RESET_TEXT: String = "Dummies reset!"

## Dummies this zone resets; wired in the arena scene via node paths.
@export var dummies: Array[TargetDummy] = []

## Status Label3D that reports the hint / reset confirmation.
@export var status_label: Label3D

## Fallback path for the status label.
@export var status_label_path: NodePath = NodePath("StatusLabel")

## Path to the reset pad (Area3D, interaction layer 3 / mask 2).
@export var reset_pad_path: NodePath = NodePath("ResetPad")


func _ready() -> void:
	_resolve_references()
	_connect_pads()
	_set_status(HINT_TEXT)


func _resolve_references() -> void:
	if status_label == null and not status_label_path.is_empty():
		var resolved_label: Node = get_node_or_null(status_label_path)
		if resolved_label is Label3D:
			status_label = resolved_label


func _connect_pads() -> void:
	var pad: Area3D = _resolve_area(reset_pad_path)
	if pad != null:
		pad.body_entered.connect(_on_reset_pad_entered)


func _resolve_area(area_path: NodePath) -> Area3D:
	if area_path.is_empty():
		return null
	var resolved: Node = get_node_or_null(area_path)
	if resolved is Area3D:
		return resolved
	return null


func _on_reset_pad_entered(_body: Node3D) -> void:
	# Deferred so the reset mutation never runs inside the body_entered physics
	# callback (AGENTS.md rule 5).
	_reset_dummies.call_deferred()


func _reset_dummies() -> void:
	for dummy: TargetDummy in dummies:
		if dummy != null:
			dummy.reset()
	_set_status(RESET_TEXT)


func _set_status(text: String) -> void:
	if status_label == null:
		return
	status_label.text = text
