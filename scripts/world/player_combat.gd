class_name PlayerCombat
extends Node3D
## Combat logic layer (design.md §5): owns the attack/dodge input buffer, the
## ground combo progression, hit-window evaluation against a hit Area3D, and the
## dodge displacement/invincibility/cooldown. It reads the animator's cached
## state/phase one-way and writes only the player's public movement-lock fields,
## so the animator->player read direction is never reversed. All logic runs in
## _physics_process; the animator updates its cached state/phase in _process, so
## combat observes them with a <=1-tick read lag (and writes movement_override
## with a <=1-tick lag) — acceptable for the 6-frame hit windows (design.md §5).

## Buffered input actions. A single slot holds at most one press; a second press
## is dropped rather than queued (design.md §5.2).
enum Action { NONE, ATTACK, DODGE }

## Player-side combat tunables + per-attack HitWindow references, preloaded like
## player.gd's PLAYER_CONFIG so the component compiles before scene wiring.
const COMBAT_CONFIG: CombatConfig = preload("res://resources/combat_config.tres")

## Player whose public movement-lock fields combat writes. Wired via @export DI.
@export var player: Player

## Fallback path resolved in _ready when the scene reference did not resolve.
@export var player_path: NodePath = NodePath("..")

## Animator whose cached state/phase/frame progress combat reads one-way.
@export var animator: PlayerAnimator

## Fallback path for the animator, mirroring player_path.
@export var animator_path: NodePath = NodePath("../Animator")

## Hit Area3D that overlap-tests damage. Wired in task 004; null-guarded so the
## script no-ops cleanly until then.
@export var hit_area: Area3D

## Fallback path for the hit area, mirroring player_path.
@export var hit_area_path: NodePath = NodePath("HitArea")

## Current combo step: 0 = none, 1..3 = attack_1..3 (design.md §5.3).
var combo_step: int = 0

## Remaining seconds a follow-up press may continue the combo after an attack
## one-shot ends; 0.0 means the chain window is closed (design.md §5.3).
var chain_timer: float = 0.0

var _buffered_action: Action = Action.NONE
var _buffer_timer: float = 0.0
var _dodge_timer: float = 0.0
var _dodge_cooldown_timer: float = 0.0
var _dodge_direction: int = 1
var _invincible: bool = false
var _window_active: bool = false
var _current_damage: float = 0.0
var _current_knockback: Vector3 = Vector3.ZERO
var _hit_targets: Array[Hurtbox] = []
## Animator state observed on the previous physics frame, used to detect when an
## attack one-shot ends so the chain window can start.
var _prev_state: StringName = PlayerAnimator.STATE_IDLE


func _ready() -> void:
	_resolve_references()
	_configure_hit_area()


func _physics_process(delta: float) -> void:
	if player == null or animator == null:
		return
	_tick_timers(delta)
	_update_combo_chain()
	_consume_buffer()
	_update_dodge(delta)
	_update_hit_window()
	_update_hit_area_position()


func _unhandled_input(event: InputEvent) -> void:
	# Combat input is gated identically to movement/jump while dialogue is open
	# (design.md §9), so attacks and dodges stay inert mid-beat.
	if DialogueService.is_open():
		return
	if event.is_action_pressed(&"attack") and not event.is_echo():
		_buffer_action(Action.ATTACK)
	elif event.is_action_pressed(&"dodge") and not event.is_echo():
		_request_dodge()


func is_invincible() -> bool:
	# Full invincibility spans the whole dodge duration (design.md §5.4); future
	# damage sources poll this before applying damage.
	return _invincible


func _resolve_references() -> void:
	if player == null and not player_path.is_empty():
		var resolved_player: Node = get_node_or_null(player_path)
		if resolved_player is Player:
			player = resolved_player
	if animator == null and not animator_path.is_empty():
		var resolved_animator: Node = get_node_or_null(animator_path)
		if resolved_animator is PlayerAnimator:
			animator = resolved_animator
	if hit_area == null and not hit_area_path.is_empty():
		var resolved_area: Node = get_node_or_null(hit_area_path)
		if resolved_area is Area3D:
			hit_area = resolved_area


func _configure_hit_area() -> void:
	# The HitArea is a scene child wired in task 004; until then this no-ops. The
	# box is resized from CombatConfig and the signal connected here so the area
	# stays in the tree and always monitors (no runtime add_child/free).
	if hit_area == null:
		return
	hit_area.area_entered.connect(_on_hit_area_entered)
	_resize_hit_box()
	_update_hit_area_position()


func _resize_hit_box() -> void:
	var resolved: Node = hit_area.get_node_or_null("CollisionShape3D")
	if resolved is CollisionShape3D:
		var shape_node: CollisionShape3D = resolved
		var box: BoxShape3D = shape_node.shape as BoxShape3D
		if box != null:
			box.size = COMBAT_CONFIG.hit_box_size


func _update_hit_area_position() -> void:
	if hit_area == null:
		return
	# The box sits in front of the player along the current facing; only x is
	# mirrored by facing, the y/z offsets are fixed (design.md §4.2).
	hit_area.position = Vector3(
		player.facing * COMBAT_CONFIG.hit_box_offset.x,
		COMBAT_CONFIG.hit_box_offset.y,
		COMBAT_CONFIG.hit_box_offset.z
	)


func _tick_timers(delta: float) -> void:
	_buffer_timer = maxf(_buffer_timer - delta, 0.0)
	_dodge_cooldown_timer = maxf(_dodge_cooldown_timer - delta, 0.0)
	chain_timer = maxf(chain_timer - delta, 0.0)
	# An expired, unconsumed buffer press is dropped (design.md §5.2).
	if _buffer_timer <= 0.0:
		_buffered_action = Action.NONE
	# A lapsed chain window resets the combo to a fresh start, but only while no
	# attack is running (chain_timer is zeroed whenever a new attack starts).
	if chain_timer <= 0.0 and combo_step != 0 and not _is_attack_state(animator.get_state()):
		combo_step = 0


func _update_combo_chain() -> void:
	var state: StringName = animator.get_state()
	# Detect the one-shot end (leaving an attack state): keep the combo alive
	# briefly for steps 1/2, and reset immediately for step 3 / the standalone
	# air attack (design.md §5.3).
	if _is_attack_state(_prev_state) and not _is_attack_state(state):
		if combo_step == 1 or combo_step == 2:
			chain_timer = COMBAT_CONFIG.chain_timeout
		else:
			combo_step = 0
		player.movement_locked = false
	_prev_state = state


func _consume_buffer() -> void:
	var state: StringName = animator.get_state()
	if _buffered_action == Action.ATTACK:
		_try_attack(state)
	elif _buffered_action == Action.DODGE:
		_try_dodge(state)


func _try_attack(state: StringName) -> void:
	if _is_attack_state(state):
		_handle_attack_during_attack(state)
		return
	# A non-attack one-shot (dodge/hit/death) must finish before the buffered
	# press may start a new attack, so hold the buffer (design.md §5.3).
	if _is_combat_state(state):
		return
	if player.is_on_floor():
		_start_ground_attack()
	else:
		_start_air_attack()
	_clear_buffer()


func _handle_attack_during_attack(state: StringName) -> void:
	# Only attack_1/attack_2 chain; the terminal steps drop the press (§5.3).
	if not _can_advance(state):
		_clear_buffer()
		return
	# A buffered press waits for the recovery cancel window, then advances in
	# place; until that window opens the buffer persists.
	if animator.is_cancel_window_open():
		_advance_combo(state)
		_clear_buffer()


func _try_dodge(state: StringName) -> void:
	# A dodge waits for the current one-shot to end before firing (§5.3), so a
	# press buffered mid-attack goes off when the attack completes.
	if _is_combat_state(state):
		return
	_start_dodge()
	_clear_buffer()


func _request_dodge() -> void:
	# A dodge press during an active dodge or its cooldown is dropped, not
	# buffered (§5.3), so a stale press never fires a surprise dodge.
	if _dodge_timer > 0.0 or _dodge_cooldown_timer > 0.0:
		return
	_buffer_action(Action.DODGE)


func _buffer_action(action: Action) -> void:
	# Single slot: a press fills it only when empty; a full slot drops the new
	# press (no queuing, design.md §5.2).
	if _buffered_action != Action.NONE:
		return
	_buffered_action = action
	_buffer_timer = COMBAT_CONFIG.input_buffer_time


func _clear_buffer() -> void:
	_buffered_action = Action.NONE
	_buffer_timer = 0.0


func _start_ground_attack() -> void:
	# combo_step + 1 selects the next strike: 0->1 fresh, 1->2 / 2->3 chain
	# continuation, and a stale 3 wraps back to 1 (a fresh restart).
	combo_step = combo_step + 1
	if combo_step > 3:
		combo_step = 1
	chain_timer = 0.0
	animator.play_combat_state(_attack_state_for_step(combo_step))
	_lock_movement()


func _start_air_attack() -> void:
	# The air attack is standalone: it abandons any combo and locks movement;
	# gravity still runs in player.gd so the strike falls with the body (§5.3).
	combo_step = 0
	chain_timer = 0.0
	animator.play_combat_state(PlayerAnimator.STATE_ATTACK_AIR)
	_lock_movement()


func _advance_combo(state: StringName) -> void:
	# Cancel the current strike once recovery is >= threshold and play the next
	# one; only attack_1/attack_2 reach here (guarded by _can_advance).
	var next_step: int = 2
	if state == PlayerAnimator.STATE_ATTACK_2:
		next_step = 3
	combo_step = next_step
	chain_timer = 0.0
	animator.play_combat_state(_attack_state_for_step(next_step))
	_lock_movement()


func _start_dodge() -> void:
	# Starting a dodge abandons any in-progress combo chain (§5.3) and records
	# the current facing so the displacement pushes the same way.
	combo_step = 0
	chain_timer = 0.0
	_dodge_timer = COMBAT_CONFIG.dodge_duration
	_dodge_direction = player.facing
	_invincible = true
	animator.play_combat_state(PlayerAnimator.STATE_DODGE)


func _update_dodge(delta: float) -> void:
	if _dodge_timer <= 0.0:
		return
	_dodge_timer = maxf(_dodge_timer - delta, 0.0)
	# X carries the displacement along the recorded facing, Z stays 0 so the
	# dodge never changes depth; gravity still runs, so an airborne dodge falls.
	player.movement_override = Vector2(
		_dodge_direction * COMBAT_CONFIG.dodge_speed, 0.0
	)
	if _dodge_timer <= 0.0:
		_end_dodge()


func _end_dodge() -> void:
	player.movement_override = Vector2.ZERO
	_invincible = false
	_dodge_cooldown_timer = COMBAT_CONFIG.dodge_cooldown


func _update_hit_window() -> void:
	var state: StringName = animator.get_state()
	var phase: StringName = animator.get_phase()
	# Opening the active phase clears the per-window hit set and latches the
	# damage/knockback; leaving the phase closes the window (design.md §5.5).
	if phase == PlayerAnimator.PHASE_ACTIVE and _is_attack_state(state):
		if not _window_active:
			_open_window(state)
	elif _window_active:
		_close_window()


func _open_window(state: StringName) -> void:
	_window_active = true
	_hit_targets.clear()
	var window: HitWindow = _hit_window_for(state)
	if window != null:
		_current_damage = window.damage
		_current_knockback = window.knockback


func _close_window() -> void:
	_window_active = false


func _on_hit_area_entered(area: Area3D) -> void:
	# Deliver once per active window to each Hurtbox. The typed check keeps the
	# coupling one-way (hitbox -> hurtbox -> dummy) without referencing
	# TargetDummy. No scene-tree mutation, so no call_deferred is required.
	if not _window_active or not (area is Hurtbox):
		return
	var hurtbox: Hurtbox = area as Hurtbox
	if _hit_targets.has(hurtbox):
		return
	_hit_targets.append(hurtbox)
	hurtbox.receive_hit(_current_damage, _current_knockback)


func _lock_movement() -> void:
	player.movement_locked = true


func _is_attack_state(state: StringName) -> bool:
	return (
		state == PlayerAnimator.STATE_ATTACK_1
		or state == PlayerAnimator.STATE_ATTACK_2
		or state == PlayerAnimator.STATE_ATTACK_3
		or state == PlayerAnimator.STATE_ATTACK_AIR
	)


func _is_combat_state(state: StringName) -> bool:
	return (
		_is_attack_state(state)
		or state == PlayerAnimator.STATE_HIT
		or state == PlayerAnimator.STATE_DODGE
		or state == PlayerAnimator.STATE_DEATH
	)


func _can_advance(state: StringName) -> bool:
	return state == PlayerAnimator.STATE_ATTACK_1 or state == PlayerAnimator.STATE_ATTACK_2


func _attack_state_for_step(step: int) -> StringName:
	if step == 1:
		return PlayerAnimator.STATE_ATTACK_1
	if step == 2:
		return PlayerAnimator.STATE_ATTACK_2
	return PlayerAnimator.STATE_ATTACK_3


func _hit_window_for(state: StringName) -> HitWindow:
	match state:
		PlayerAnimator.STATE_ATTACK_1:
			return COMBAT_CONFIG.attack_1_window
		PlayerAnimator.STATE_ATTACK_2:
			return COMBAT_CONFIG.attack_2_window
		PlayerAnimator.STATE_ATTACK_3:
			return COMBAT_CONFIG.attack_3_window
		PlayerAnimator.STATE_ATTACK_AIR:
			return COMBAT_CONFIG.attack_air_window
		_:
			return null
