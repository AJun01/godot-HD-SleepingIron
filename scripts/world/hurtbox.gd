class_name Hurtbox
extends Area3D
## Thin damage receiver (design.md §7): an Area3D child of a hittable target that
## re-emits incoming hits as a typed signal. It has no dependency on PlayerCombat
## or TargetDummy, keeping the hitbox -> hurtbox -> target coupling strictly
## one-way. It is a forwarder, not a general Damageable framework.

## Emitted for every received hit; the owning target connects and reacts.
signal hit_received(damage: float, knockback: Vector3)


## Re-emits an incoming hit so the owner can respond (hit-flash, HP, ...).
func receive_hit(damage: float, knockback: Vector3) -> void:
	hit_received.emit(damage, knockback)
