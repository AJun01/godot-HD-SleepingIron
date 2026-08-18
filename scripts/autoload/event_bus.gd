extends Node
## Autoload signal bus for cross-scene events (AGENTS.md rule #2). Carries
## signals only — no logic. Scenes and services connect here instead of reaching
## into each other's nodes.

## State values are GameFlow.State members. Typed as `int` so this lowest-level
## autoload carries no dependency on GameFlow's script type.
signal game_state_changed(from_state: int, to_state: int)

## Emitted by GameFlow when a stage transition starts, carrying the new stage's
## index and its objective. objective is empty for menu and ending stages.
signal stage_changed(stage_index: int, objective: String)

## Emitted by SceneRouter when a fade transition begins.
signal transition_started(scene_path: String)

## Emitted by SceneRouter when a fade transition fully completes.
signal transition_finished(scene_path: String)
