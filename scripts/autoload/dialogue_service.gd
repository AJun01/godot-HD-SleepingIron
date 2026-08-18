extends Node
## Autoload dialogue service. Owns the minimal dialogue bar and its line-by-line
## advance state machine. It is the only consumer of DialogueData: callers hand a
## DialogueData to play() and await completion, so a future full dialogue system
## can replace this service without any caller changing (design.md swap contract).

## Emitted when the advance action is pressed while open, and on a forced close,
## so an in-flight play() coroutine resumes and unwinds.
signal advance_pressed

## Draw order for the bar's CanvasLayer; below SceneRouter's 100 fade layer.
const BAR_LAYER: int = 90

## Horizontal inset from the viewport edges (pixels).
const BAR_MARGIN_SIDE: float = 120.0
## Vertical gap between the bar bottom and the viewport bottom (pixels).
const BAR_MARGIN_BOTTOM: float = 40.0
## Bar height (pixels); tall enough for a wrapped line plus the speaker.
const BAR_HEIGHT: float = 160.0
const TEXT_PADDING_HORIZONTAL: float = 24.0
const TEXT_PADDING_VERTICAL: float = 16.0
const SPEAKER_FONT_SIZE: int = 22
const LINE_FONT_SIZE: int = 28

var _is_open: bool = false
var _force_close: bool = false
var _panel: Panel = null
var _speaker_label: Label = null
var _line_label: Label = null


func _ready() -> void:
	EventBus.transition_started.connect(_on_transition_started)


func is_open() -> bool:
	return _is_open


func play(dialogue: DialogueData) -> void:
	if _is_open:
		return
	if dialogue == null or dialogue.lines.is_empty():
		return
	_ensure_bar()
	_is_open = true
	_force_close = false
	_speaker_label.text = dialogue.speaker
	_speaker_label.visible = not dialogue.speaker.is_empty()
	for line: String in dialogue.lines:
		_line_label.text = line
		_panel.visible = true
		await advance_pressed
		if _force_close:
			break
	_close()


func _close() -> void:
	_panel.visible = false
	_is_open = false
	_force_close = false


func _on_transition_started(_scene_path: String) -> void:
	if not _is_open:
		return
	_force_close = true
	advance_pressed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed(&"advance") and not event.is_echo():
		# Consume the press so advancing a line can't also leak to other input.
		get_viewport().set_input_as_handled()
		advance_pressed.emit()


func _ensure_bar() -> void:
	if _panel != null:
		return
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "DialogueLayer"
	layer.layer = BAR_LAYER
	var panel: Panel = Panel.new()
	panel.name = "DialogueBar"
	panel.visible = false
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = BAR_MARGIN_SIDE
	panel.offset_right = -BAR_MARGIN_SIDE
	panel.offset_top = -(BAR_MARGIN_BOTTOM + BAR_HEIGHT)
	panel.offset_bottom = -BAR_MARGIN_BOTTOM
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Lines"
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = TEXT_PADDING_HORIZONTAL
	box.offset_right = -TEXT_PADDING_HORIZONTAL
	box.offset_top = TEXT_PADDING_VERTICAL
	box.offset_bottom = -TEXT_PADDING_VERTICAL
	var speaker_label: Label = Label.new()
	speaker_label.name = "SpeakerLabel"
	speaker_label.add_theme_font_size_override("font_size", SPEAKER_FONT_SIZE)
	speaker_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45))
	var line_label: Label = Label.new()
	line_label.name = "LineLabel"
	line_label.add_theme_font_size_override("font_size", LINE_FONT_SIZE)
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(speaker_label)
	box.add_child(line_label)
	panel.add_child(box)
	layer.add_child(panel)
	add_child(layer)
	_panel = panel
	_speaker_label = speaker_label
	_line_label = line_label
