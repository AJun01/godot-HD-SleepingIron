extends Node
## Central linear progression state machine (AGENTS.md Architecture law: linear
## game, single entry for all progression). Scenes never advance themselves;
## they only call the request_* methods below, each guarded by the current state
## so duplicate or out-of-sequence transitions are impossible.

enum State {
	BOOT,
	MENU,
	CHAPTER,
	TRANSITIONING,
}

const FLOW_CONFIG: FlowConfig = preload("res://resources/flow_config.tres")

var _state: State = State.BOOT
var _current_stage_index: int = -1
var _pending_state: State = State.BOOT
var _state_before_transition: State = State.BOOT
var _auto_return_timer: SceneTreeTimer = null
var _auto_return_stage_index: int = -1


func _ready() -> void:
	EventBus.transition_finished.connect(_on_transition_finished)


func start_flow() -> void:
	if _state != State.BOOT:
		return
	_transition_to_stage(0)


func request_new_game() -> void:
	if _state != State.MENU:
		return
	_transition_to_stage(_current_stage_index + 1)


func request_advance_stage() -> void:
	if _state != State.CHAPTER:
		return
	_transition_to_stage(_current_stage_index + 1)


func request_quit_to_menu() -> void:
	if _state != State.CHAPTER:
		return
	_transition_to_stage(0)


func request_quit() -> void:
	if _state != State.MENU:
		return
	get_tree().quit()


func _transition_to_stage(stage_index: int) -> void:
	if stage_index < 0 or stage_index >= FLOW_CONFIG.stages.size():
		return
	var stage: FlowStage = FLOW_CONFIG.stages[stage_index]
	_current_stage_index = stage_index
	_pending_state = _state_for_stage_tag(stage.state)
	_state_before_transition = _state
	_set_state(State.TRANSITIONING)
	var started: bool = SceneRouter.transition_to(stage.scene_path)
	if not started:
		# SceneRouter was already busy; roll back so the state stays consistent.
		_set_state(_state_before_transition)
		return
	# Emitted only after transition_to confirms the request started: the HUD must
	# update at fade-start and never on a rolled-back (busy) request.
	EventBus.stage_changed.emit(stage_index, stage.objective)


func _state_for_stage_tag(stage_tag: StringName) -> State:
	match stage_tag:
		&"menu":
			return State.MENU
		&"chapter":
			return State.CHAPTER
		_:
			return State.BOOT


func _on_transition_finished(_scene_path: String) -> void:
	if _state != State.TRANSITIONING:
		return
	_set_state(_pending_state)
	_start_auto_return_if_needed()


## Schedules the stage's own return to the menu. The timing belongs to the state
## machine, never to the stage's scene (AGENTS.md Architecture law).
func _start_auto_return_if_needed() -> void:
	_cancel_auto_return()
	if _state != State.CHAPTER:
		return
	var stage: FlowStage = FLOW_CONFIG.stages[_current_stage_index]
	if stage.auto_return_delay <= 0.0:
		return
	_auto_return_stage_index = _current_stage_index
	_auto_return_timer = get_tree().create_timer(stage.auto_return_delay)
	_auto_return_timer.timeout.connect(_on_auto_return_timeout)


func _cancel_auto_return() -> void:
	var timer: SceneTreeTimer = _auto_return_timer
	_auto_return_timer = null
	_auto_return_stage_index = -1
	if timer != null and timer.timeout.is_connected(_on_auto_return_timeout):
		timer.timeout.disconnect(_on_auto_return_timeout)


func _on_auto_return_timeout() -> void:
	var scheduling_stage_index: int = _auto_return_stage_index
	_auto_return_timer = null
	_auto_return_stage_index = -1
	# The flow may have moved on while the timer ran; only the stage that
	# scheduled this return, still active, may trigger it.
	if scheduling_stage_index != _current_stage_index or _state != State.CHAPTER:
		return
	request_quit_to_menu()


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	var previous: State = _state
	_state = new_state
	EventBus.game_state_changed.emit(previous, new_state)
