extends Node
## Central linear progression state machine (AGENTS.md Architecture law: linear
## game, single entry for all progression). Scenes never advance themselves; this
## is the only caller of SceneRouter. Currently a single-stage flow: boot
## transitions straight into the dev-hub arena and no other stage is reachable.

enum State {
	BOOT,
	ARENA,
	TRANSITIONING,
}

## The single development stage. A const path (not data-driven) because the hub
## is one terminal stage; the EventBus/SceneRouter backbone stays so future
## stages can be re-added without changing this machine's coupling surface.
const ARENA_SCENE_PATH: String = "res://scenes/act/arena.tscn"

var _state: State = State.BOOT
var _pending_state: State = State.BOOT


func _ready() -> void:
	EventBus.transition_finished.connect(_on_transition_finished)


func start_flow() -> void:
	if _state != State.BOOT:
		return
	_transition_to_arena()


func _transition_to_arena() -> void:
	_pending_state = State.ARENA
	_set_state(State.TRANSITIONING)
	var started: bool = SceneRouter.transition_to(ARENA_SCENE_PATH)
	if not started:
		# SceneRouter was already busy; roll back so the state stays consistent.
		_set_state(State.BOOT)
		return
	# Emitted only after transition_to confirms the request started: the HUD must
	# update at fade-start and never on a rolled-back (busy) request. The arena
	# carries no objective, so the empty string keeps ObjectiveHud hidden while
	# still exercising the stage_changed contract future listeners rely on.
	EventBus.stage_changed.emit(0, "")


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
