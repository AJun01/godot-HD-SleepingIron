class_name HitWindow
extends Resource
## Frame-accurate damage window for a single attack (AGENTS.md rule #4: gameplay
## values live in Resources, never hardcoded in scripts).

## First active frame (inclusive, 0-based); earlier frames are the wind-up phase.
@export var start_frame: int = 2

## Last active frame (inclusive); later frames are the recovery phase.
@export var end_frame: int = 3

## Damage dealt once per target while the window is active.
@export var damage: float = 35.0

## Knockback impulse delivered with the hit; reserved for future dynamic targets
## (the static dummy ignores it).
@export var knockback: Vector3 = Vector3.ZERO
