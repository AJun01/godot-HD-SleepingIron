class_name TransitionConfig
extends Resource
## Tunable values for SceneRouter's full-screen fade (AGENTS.md rule #4).

## Seconds the fade takes in each direction; fade-out and fade-in are symmetric.
@export var fade_duration: float = 0.5

## Color the screen fades to at full opacity. The alpha channel is the peak fade.
@export var fade_color: Color = Color(0.0, 0.0, 0.0, 1.0)
