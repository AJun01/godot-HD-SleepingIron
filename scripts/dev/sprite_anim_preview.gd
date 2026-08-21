extends Node2D
## Dev-only preview that plays the produced SpriteFrames resource so every
## animation and the left-facing flip_h mirror can be verified. Self-contained:
## it reads the InputMap actions directly and needs no EventBus (AGENTS.md rule 2).

## Animation names in map order (docs/character-sprite-mapping.md §4). The
## SpriteFrames API returns names in hash order, so the documented order is kept
## here for a predictable preview cycle.
const ANIMATIONS: Array[StringName] = [
	&"idle",
	&"run",
	&"jump",
	&"fall",
	&"land",
	&"attack_1",
	&"attack_2",
	&"attack_3",
	&"attack_air",
	&"hit",
	&"dodge",
	&"death",
]

var _index: int = 0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_print_state()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_right"):
		_step(1)
	elif Input.is_action_just_pressed("move_left"):
		_step(-1)
	elif Input.is_action_just_pressed("advance"):
		_sprite.flip_h = not _sprite.flip_h
		_print_state()


func _step(delta: int) -> void:
	_index = posmod(_index + delta, ANIMATIONS.size())
	_sprite.animation = ANIMATIONS[_index]
	_sprite.play()
	_print_state()


func _print_state() -> void:
	print("[sprite_anim_preview] %s (flip_h=%s)" % [ANIMATIONS[_index], str(_sprite.flip_h)])
