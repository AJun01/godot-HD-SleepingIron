class_name PlayerConfig
extends Resource
## Tunable movement + jump values for the side-view player (AGENTS.md rule #4:
## gameplay values live in Resources, never hardcoded in scripts).

## Horizontal speed (units/s) at full input deflection in the RUN tier
## (double-tap). Existing 7.0 default unchanged.
@export var move_speed: float = 7.0

## Horizontal speed (units/s) at full input deflection in the WALK tier
## (hold a direction). Lower than move_speed for DNF-style two-tier movement.
@export var walk_speed: float = 3.5

## Window (s) in which a second press of the SAME direction key upgrades
## movement to the RUN tier.
@export var double_tap_window: float = 0.25

## Acceleration toward move_speed in units/second^2; higher = snappier start.
@export var acceleration: float = 60.0

## Friction applied when there is no input, in units/second^2.
@export var friction: float = 70.0

## Downward acceleration applied while airborne, in units/second^2.
@export var gravity: float = 22.0

## Upward velocity applied at the start of a jump, in units/second.
@export var jump_velocity: float = 8.5

## Seconds before landing in which a jump press is buffered and fired on landing.
@export var jump_buffer_time: float = 0.1

## Multiplier applied to upward velocity when jump is released mid-ascent, so a
## tap yields a shorter hop than a held jump.
@export var jump_cut_factor: float = 0.5
