class_name TargetDummy
extends StaticBody3D
## Hittable target dummy (design.md §8): a self-contained StaticBody3D that
## receives hits through its child Hurtbox and reacts with a modulate hit-flash,
## a billboarded health bar whose fill scale.x tracks hp/max_hp, a darkened dead
## state, and a timed auto-reset to full HP. All tunables are @export (rule 4);
## the knockback payload is accepted but ignored because a static body cannot
## move and the dummy positions are an arena invariant. The combat-range reset
## pad restores dummies through the public reset() method.

## Modulate applied while dead; the darkened tint reads as "not hittable".
const DEATH_MODULATE: Color = Color(0.35, 0.35, 0.35, 1.0)

## Max HP before death; the three arena instances set 100 / 60 / 30.
@export var max_hp: float = 100.0

## Seconds a dummy stays dead before auto-resetting to full HP.
@export var reset_delay: float = 2.0

## Duration of the hit-flash modulate pulse, in seconds.
@export var hit_flash_duration: float = 0.12

## Modulate color applied for one pulse on a non-fatal hit.
@export var hit_flash_color: Color = Color(1.0, 0.25, 0.25)

## Sprite3D whose modulate pulses on hit. Wired via @export DI.
@export var sprite: Sprite3D

## Fallback path for the sprite, mirroring the dev-zone path pattern.
@export var sprite_path: NodePath = NodePath("Sprite3D")

## Hurtbox that forwards incoming hits to take_damage via hit_received.
@export var hurtbox: Hurtbox

## Fallback path for the hurtbox.
@export var hurtbox_path: NodePath = NodePath("Hurtbox")

## Red fill quad of the billboard health bar; scale.x tracks hp/max_hp.
@export var health_bar_fill: MeshInstance3D

## Fallback path for the fill quad.
@export var health_bar_fill_path: NodePath = NodePath("HealthBar/Fill")

## Root of the billboard health bar, hidden while dead.
@export var health_bar_root: Node3D

## Fallback path for the health bar root.
@export var health_bar_root_path: NodePath = NodePath("HealthBar")

var _hp: float = 0.0
var _dead: bool = false
var _reset_timer: float = 0.0
var _flash_tween: Tween


func _ready() -> void:
	_resolve_references()
	if hurtbox != null:
		hurtbox.hit_received.connect(take_damage)
	_hp = max_hp
	_update_health_bar()


func _process(delta: float) -> void:
	# Only a dead dummy counts down its auto-reset; living dummies do no per-frame
	# work, so three dummies stay cheap.
	if not _dead:
		return
	_reset_timer = maxf(_reset_timer - delta, 0.0)
	if _reset_timer <= 0.0:
		reset()


## Applies one hit. knockback is accepted but deliberately ignored: a
## StaticBody3D cannot move and the dummy positions are an arena invariant, so
## the payload is retained only for a future dynamic damage receiver
## (design.md §7/§8).
func take_damage(damage: float, _knockback: Vector3) -> void:
	if _dead:
		return
	_hp = maxf(_hp - damage, 0.0)
	if _hp <= 0.0:
		_dead = true
		_reset_timer = reset_delay
	# Feedback is deferred so no scene-tree or physics mutation runs inside the
	# area_entered physics callback that delivered the hit (AGENTS.md rule 5).
	_apply_hit_feedback.call_deferred()


## Restores full HP, clears the dead state, and re-enables the hurtbox. Shared
## by the auto-reset timer and the combat-range reset pad.
func reset() -> void:
	_dead = false
	_reset_timer = 0.0
	_hp = max_hp
	_kill_flash_tween()
	if sprite != null:
		sprite.modulate = Color.WHITE
	if hurtbox != null:
		hurtbox.monitoring = true
		hurtbox.monitorable = true
	if health_bar_root != null:
		health_bar_root.visible = true
	_update_health_bar()


func _resolve_references() -> void:
	if sprite == null and not sprite_path.is_empty():
		var resolved_sprite: Node = get_node_or_null(sprite_path)
		if resolved_sprite is Sprite3D:
			sprite = resolved_sprite
	if hurtbox == null and not hurtbox_path.is_empty():
		var resolved_hurtbox: Node = get_node_or_null(hurtbox_path)
		if resolved_hurtbox is Hurtbox:
			hurtbox = resolved_hurtbox
	if health_bar_fill == null and not health_bar_fill_path.is_empty():
		var resolved_fill: Node = get_node_or_null(health_bar_fill_path)
		if resolved_fill is MeshInstance3D:
			health_bar_fill = resolved_fill
	if health_bar_root == null and not health_bar_root_path.is_empty():
		var resolved_root: Node = get_node_or_null(health_bar_root_path)
		if resolved_root is Node3D:
			health_bar_root = resolved_root


func _apply_hit_feedback() -> void:
	if _dead:
		_enter_dead_state()
	else:
		_flash_sprite()
		_update_health_bar()


func _enter_dead_state() -> void:
	# A dead dummy stops reporting hits and reads as "down": kill any in-flight
	# flash, darken the sprite, hide the bar, and disable the hurtbox so later
	# hits do nothing until reset (design.md §8).
	_kill_flash_tween()
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
	if sprite != null:
		sprite.modulate = DEATH_MODULATE
	if health_bar_root != null:
		health_bar_root.visible = false
	_update_health_bar()


func _flash_sprite() -> void:
	if sprite == null:
		return
	_kill_flash_tween()
	sprite.modulate = hit_flash_color
	# A short tween lerps modulate back to white for the pulse (design.md §8).
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, hit_flash_duration)


func _update_health_bar() -> void:
	if health_bar_fill == null:
		return
	# The fill quad is left-anchored (QuadMesh center_offset), so shrinking
	# scale.x from 1 drains it right-to-left toward the fixed left edge.
	var ratio: float = clampf(_hp / max_hp, 0.0, 1.0)
	health_bar_fill.scale.x = ratio


func _kill_flash_tween() -> void:
	if _flash_tween != null and is_instance_valid(_flash_tween):
		_flash_tween.kill()
	_flash_tween = null
