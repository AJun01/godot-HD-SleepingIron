extends Node
## Autoload that owns scene routing. Runs a full-screen fade through a
## lazily-created CanvasLayer + ColorRect, swaps scenes with `call_deferred` so
## no tree mutation happens mid-signal, and refuses requests while a transition
## is in flight.

const TRANSITION_CONFIG: TransitionConfig = preload("res://resources/transition_config.tres")

## CanvasLayer draw order; high enough to cover the world and UI beneath it.
const OVERLAY_LAYER: int = 100

var _overlay: ColorRect = null
var _is_transitioning: bool = false


func is_transitioning() -> bool:
	return _is_transitioning


func transition_to(scene_path: String) -> bool:
	if _is_transitioning:
		return false
	_is_transitioning = true
	EventBus.transition_started.emit(scene_path)
	_run_transition(scene_path)
	return true


func _run_transition(scene_path: String) -> void:
	var overlay: ColorRect = _get_overlay()
	overlay.visible = true
	overlay.color = Color(
		TRANSITION_CONFIG.fade_color.r,
		TRANSITION_CONFIG.fade_color.g,
		TRANSITION_CONFIG.fade_color.b,
		0.0
	)
	var tween: Tween = create_tween()
	tween.tween_property(
		overlay,
		"color:a",
		TRANSITION_CONFIG.fade_color.a,
		TRANSITION_CONFIG.fade_duration
	)
	await tween.finished
	# Defer the swap so the tree mutation never runs inside a signal callback.
	get_tree().call_deferred("change_scene_to_file", scene_path)
	await get_tree().scene_changed
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, TRANSITION_CONFIG.fade_duration)
	await tween.finished
	overlay.visible = false
	_is_transitioning = false
	EventBus.transition_finished.emit(scene_path)


func _get_overlay() -> ColorRect:
	if _overlay == null:
		var layer: CanvasLayer = CanvasLayer.new()
		layer.name = "TransitionOverlay"
		layer.layer = OVERLAY_LAYER
		_overlay = ColorRect.new()
		_overlay.name = "FadeRect"
		_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
		_overlay.anchor_right = 1.0
		_overlay.anchor_bottom = 1.0
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_overlay)
		add_child(layer)
	return _overlay
