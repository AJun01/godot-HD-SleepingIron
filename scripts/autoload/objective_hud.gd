extends Node
## Autoload objective HUD. Renders the active stage's objective in a top-left
## Label that survives scene swaps. Driven entirely by EventBus.stage_changed,
## which GameFlow emits at fade-start, so the text reflects the stage being
## entered and can never lag behind; an empty objective (menu/ending) hides it.

## Draw order for the HUD's CanvasLayer; below SceneRouter's 100 fade layer and
## the dialogue bar's 90 so objective text is never rendered over either.
const HUD_LAYER: int = 20

## Margin from the viewport top edge (pixels).
const HUD_MARGIN_TOP: float = 24.0
## Horizontal inset from the viewport edges (pixels).
const HUD_MARGIN_SIDE: float = 24.0
const OBJECTIVE_FONT_SIZE: int = 28

var _label: Label = null


func _ready() -> void:
	EventBus.stage_changed.connect(_on_stage_changed)


func _on_stage_changed(_stage_index: int, objective: String) -> void:
	if _label == null:
		# First update must also build the tree; defer so the mutation never runs
		# inside the signal callback (AGENTS.md GDScript rule #5).
		_show_objective.call_deferred(objective)
		return
	_show_objective(objective)


func _show_objective(objective: String) -> void:
	_ensure_hud()
	_label.text = objective
	# An empty objective marks menu/ending stages; hiding here guarantees the HUD
	# never keeps showing a previous stage's text during those states.
	_label.visible = not objective.is_empty()


func _ensure_hud() -> void:
	if _label != null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "ObjectiveHudLayer"
	layer.layer = HUD_LAYER
	var label: Label = Label.new()
	label.name = "ObjectiveLabel"
	label.visible = false
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_left = HUD_MARGIN_SIDE
	label.offset_right = -HUD_MARGIN_SIDE
	label.offset_top = HUD_MARGIN_TOP
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", OBJECTIVE_FONT_SIZE)
	layer.add_child(label)
	add_child(layer)
	_label = label
