extends Node3D
## Zone pillar: a billboarded Label3D that states a zone's system name, its
## one-line responsibility, and the related file paths. Content is injected via
## @export (AGENTS.md rule 2) and composed into the label in _ready; the label
## node is resolved defensively by path, matching side_view_camera.gd.

## System name rendered as the label's first line.
@export var title: String = ""

## One-line responsibility of the system this zone exercises.
@export var responsibility: String = ""

## Related file paths, one per line, pointing at the code behind the system.
@export var paths: PackedStringArray = PackedStringArray()

## Path to the Label3D child that renders the composed text.
@export var label_path: NodePath = NodePath("Label3D")

var _label: Label3D


func _ready() -> void:
	_resolve_label()
	_compose_text()


func _resolve_label() -> void:
	if not label_path.is_empty():
		var resolved: Node = get_node_or_null(label_path)
		if resolved is Label3D:
			_label = resolved


func _compose_text() -> void:
	if _label == null:
		return
	var lines: PackedStringArray = PackedStringArray()
	if not title.is_empty():
		lines.append(title)
		lines.append("")
	if not responsibility.is_empty():
		lines.append(responsibility)
		lines.append("")
	for path: String in paths:
		lines.append(path)
	_label.text = "\n".join(lines)
