class_name PlayerConfig
extends Resource
## Tunable horizontal-movement values for the chapter player (AGENTS.md rule #4:
## gameplay values live in Resources, never hardcoded in scripts).

## Horizontal speed in units/second reached at full input deflection.
@export var move_speed: float = 6.0

## Acceleration toward move_speed in units/second^2; higher = snappier start.
@export var acceleration: float = 40.0

## Friction applied when there is no input, in units/second^2.
@export var friction: float = 50.0
