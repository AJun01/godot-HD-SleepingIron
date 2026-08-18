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
	_pending_state = _state_for_stage_id(stage.id)
	_state_before_transition = _state
	_set_state(State.TRANSITIONING)
	var started: bool = SceneRouter.transition_to(stage.scene_path)
	if not started:
		# SceneRouter was already busy; roll back so the state stays consistent.
		_set_state(_state_before_transition)


func _state_for_stage_id(stage_id: StringName) -> State:
	match stage_id:
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


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	var previous: State = _state
	_state = new_state
	EventBus.game_state_changed.emit(previous, new_state)
