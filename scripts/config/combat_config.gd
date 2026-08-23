class_name CombatConfig
extends Resource
## Player-side combat tunables plus references to the four per-attack HitWindow
## resources (AGENTS.md rule #4: gameplay values live in Resources).

## Seconds an attack/dodge press is buffered before being dropped.
@export var input_buffer_time: float = 0.15

## Seconds after an attack ends during which a follow-up continues the combo.
@export var chain_timeout: float = 0.4

## Recovery-phase progress (0..1) at which the next combo step may cancel in.
@export var cancel_recovery_threshold: float = 0.6

## Horizontal speed during a dodge, in units/second.
@export var dodge_speed: float = 12.0

## Duration of the dodge and its full invincibility window, in seconds.
@export var dodge_duration: float = 0.3

## Cooldown after a dodge ends before another dodge may start, in seconds.
@export var dodge_cooldown: float = 0.5

## Size of the hit Area3D collision box, in world units.
@export var hit_box_size: Vector3 = Vector3(1.0, 1.6, 0.8)

## Center of the hit box relative to the player; x is mirrored along facing.
@export var hit_box_offset: Vector3 = Vector3(0.7, 0.0, 0.0)

## HitWindow for the first ground combo strike.
@export var attack_1_window: HitWindow

## HitWindow for the second ground combo strike.
@export var attack_2_window: HitWindow

## HitWindow for the third (final) ground combo strike.
@export var attack_3_window: HitWindow

## HitWindow for the airborne strike.
@export var attack_air_window: HitWindow
