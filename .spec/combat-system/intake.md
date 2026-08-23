# Intake: Combat System

## PR target branch
master

## Raw prompt
Start the combat system (SDD flow) for Sleeping Iron HD-2D. Wire the
attack_1/2/3 combo, attack_air, hit, dodge, and death animations into the
player; attacks have wind-up / hit-stun / recovery phases driven by the
animation state machine (extend player_animator, stay composable, no god
scripts); hit windows live in Resource files (frame intervals + damage and
other tunables, AGENTS.md rule 4); the arena target dummies become hittable
targets (hit feedback, health bar, death) so the combo can be tested against
them; learning-first and extensible — the combat system is a minimal closed
loop only, future work adds enemy AI / systematic damage-receiver support.
See `# 战斗系统需求（此前与用户对齐的方向，Phase 0 再逐条确认）` in the
original request for the full alignment list.

## Clarifications (Q&A)

### Q1 — Feature behavior: combo input rhythm
**Recommended:** DNF-style lenient combo: each attack can be canceled into the
next step during the recovery tail (animation progress >= 60%); 0.15s input
buffer on the attack key; return to idle 0.4s after recovery ends with no
follow-up; buffer at most one press, no queuing.
**User answered:** DNF-style lenient combo (recommended values accepted).

### Q2 — Feature behavior: movement lock during attacks
**Recommended:** Ground attacks (attack_1/2/3) fully lock X/Z movement;
attack_air locks movement input and decays horizontal momentum to 0 while
gravity continues; dodge carries its own movement.
**User answered:** Lock movement during attacks (recommended).

### Q3 — Feature behavior: hit/death scope
**Recommended:** hit/death enter the state machine as states only (playable
via preview mode, return to idle when finished). No player HP, no damage
source in this feature; player damage/death logic is deferred to a future
enemy-AI feature.
**User answered:** States only, no player HP (recommended).

### Q4 — Feature behavior: dodge spec
**Recommended:** Rolling dash displacement (speed x duration, tunable) +
full invincibility + 0.5s cooldown; usable grounded and airborne; all
parameters live in a Resource.
**User answered:** Displacement + invincibility + cooldown (recommended).

### Q5 — Feature behavior: target dummy spec
**Recommended:** Three dummies share one TargetDummy component: hit-flash
(modulate pulse) + billboard health bar + death behavior; auto-reset to full
HP 2s after death; HP / damage / knockback all Resource tunables; dummies
use different max HP (e.g. 100/60/30) to exercise combo damage.
**User answered:** Hit-flash + health bar + auto-reset (recommended).

### Q6 — Reference files: Gold Standard
**Recommended:** `scripts/world/player_animator.gd` is the Gold Standard;
the other four candidates are supporting references.
**User answered:** player_animator.gd is the Gold Standard.

### Q7 — Architecture fit: component split
**Recommended:** Three-layer split: (1) player_animator.gd extended into the
full combat animation state machine (attack_1/2/3, attack_air, hit, dodge;
animation-driven wind-up/hit-stun/recovery phases), still reading the player
one-way; (2) a new composable player_combat.gd component owning attack input
buffer, combo progression, hit-window Resource evaluation, hit Area3D
generation, dodge displacement + invincibility; (3) player.gd gains only a
minimal public movement-lock interface set by the components (no reverse
references). Hit windows are a new Resource in resources/.
**User answered:** Three-layer split (recommended).

## Confirmed feature behavior

- **Inputs:** new `attack` input action (combo step / attack_air when
  airborne) and new `dodge` input action; existing movement/jump inputs and
  their feel are unchanged.
- **Outputs:** combo attacks with per-step wind-up / active (hit-window) /
  recovery phases; hittable target dummies with hit-flash, health bar,
  death, and auto-reset; dodge with displacement + invincibility + cooldown;
  hit/death states playable via the animator preview path.
- **Edge cases handled:** attack pressed while airborne → attack_air (no
  ground-combo step); attack pressed mid-dodge or mid-hit → buffered per Q1
  rules or ignored per state; dodge pressed during an attack → ignored until
  recovery ends (buffered once); dummy killed mid-combo → later hits do
  nothing until reset; dialogue open → combat inputs inert (same gate as
  movement/jump); combo chain timeout returns to idle.
- **Out of scope:** player HP, damage sources, enemy AI, systematic
  damage-receiver framework, hit-stop/camera shake, SFX/VFX for combat
  (placeholders only where an asset is strictly required), save data for
  combat state.

## Reference Files (confirmed by user)

- `scripts/world/player_animator.gd` — **Gold Standard**: composable state
  machine, one-way dependency (animator reads player), preview mode, hold
  one-shots until animation_finished.
- `scripts/world/player.gd` — jump-buffer timer pattern to mirror for the
  attack buffer; input gating via DialogueService.
- `scripts/config/player_config.gd` — Resource tunables pattern for the new
  hit-window / combat config Resource.
- `scripts/dev/animation_preview_zone.gd` — dev-zone controller pattern
  (Area3D pads on interaction layer 3 / mask 2, call_deferred mutations,
  Label3D status) for the combat-range controller.
- `scripts/autoload/event_bus.gd` — typed signal bus, only if combat needs
  cross-scene events (minimal loop should avoid it unless justified).

## Architecture constraints (confirmed)

- Composable components + `@export` dependency injection; no god scripts
  (AGENTS.md architecture law + rule 2/3).
- Three-layer split confirmed in Q7: animator = animation layer, new
  player_combat = logic layer, player.gd = physics with a minimal public
  lock interface.
- One-way dependency preserved: animator reads player; combat reads animator
  state and writes only public lock fields/methods on the injected player.
- Tunables live in Resource files or `@export` — never hardcoded gameplay
  values (rule 4): hit-window frame intervals + damage + knockback, dodge
  speed/duration/cooldown, dummy HP, combo buffer/cancel/window timings.
- `call_deferred` for scene-tree mutations from physics/signal callbacks
  (rule 5); explicit collision layers/masks everywhere (rule 6).
- Static typing everywhere (rule 1).

## Reuse (do NOT recreate)

- `player_animator.gd` preview mode as the verification path for hit/death
  states (no damage source exists in this feature).
- Jump-buffer pattern in `scripts/world/player.gd` for the attack buffer.
- Area3D pad + `call_deferred` dev-zone pattern from `scripts/dev/*.gd`
  (interaction layer 3 / mask 2) for the combat-range controller.
- `assets/placeholders/placeholder_target_dummy.svg` as the dummy base art;
  any new combat placeholder art goes to `assets/placeholders/` and is
  registered with `status: placeholder` in
  `docs/sdd/artifacts/combat-system.yml` (godot-sdd skill).
- Existing PlayerConfig Resource as the pattern for the new combat config
  Resource; consider extending it vs. a sibling Resource (Tech Lead call).

## Unverified assumptions (RISK)

- Concrete numbers (damage per combo step, dummy max HP 100/60/30, knockback,
  dodge speed/duration/cooldown, combo cancel/buffer/window timings) are
  sensible defaults chosen by the Tech Lead; every one must be a Resource
  tunable, never hardcoded.
- New `attack`/`dodge` input actions need `project.godot` input-map entries;
  default bindings are the Tech Lead's call (e.g. attack = J, dodge = K,
  joypad face buttons), documented in the task so the user can rebind.
- hit/death have no trigger source in this feature; verified via preview
  mode only (accepted in Q3).
- The player scene gains the PlayerCombat node; scene wiring edits to
  `scenes/actors/player.tscn` and the arena CombatRange zone are expected.
