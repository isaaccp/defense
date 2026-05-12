# Defense — Agent Guide

## Project Overview
A roguelike tower-defense game in **Godot 4.7**. Players select heroes, place them in levels, and survive enemy waves. Between levels, they unlock skills that modify hero behaviors. Supports local and online (Nakama) multiplayer.

## Key Architecture Patterns

### Component System
All game actors (`Actor` base class) are built from components. To find a component on a node:
```gdscript
var vitals = Component.get_or_null(actor, VitalsComponent.component)
# or, when it must exist:
var vitals = Component.get_or_die(actor, VitalsComponent.component)
```
Components have `run()` / `stop()` lifecycle methods. Never call component logic before `run()`.

### State Machines
Three nested state machines:
- **Gameplay** (`gameplay.gd`): `MENU → PRE_RUN → RUN`
- **Run** (`run/run.gd`): `CHARACTER_SELECTION → WITHIN_LEVEL → BETWEEN_LEVELS → RUN_SUMMARY`
- **Level** (`levels/level.gd`): `PREPARE → COMBAT → SUMMARY → DONE`

Use `StateMachine` / `StateMachineStack` from `util/` — don't manage state transitions manually.

### Behavior / AI System
Enemy and hero AI is rule-based. Each actor has a `BehaviorComponent` that evaluates `Rule` objects each physics frame. Rules are composed of:
- **Conditions** (`behavior/conditions/`) — booleans about game state
- **Target selectors** (`behavior/target_selection/`) — who to act on
- **Actions** (`behavior/actions/`) — what to do

Behaviors are serialized as `StoredBehavior` resources (`.tres`) and restored at runtime via `SkillManager` autoload.

See `behavior/BEHAVIOR.md` for a full walkthrough of the stored-vs-runtime split, the param system, action lifecycle, and how to add new skills or configurable params to existing actions.

### Skill & Effect System
- Skills are `Resource` subclasses with a `SkillType` enum: `ACTION`, `TARGET`, `CONDITION`, `TARGET_SORT`, `META_SKILL`.
- Relics / statuses live in `effects/` as `.tres` files registered in `relic_library.tres` / `status_library.tres`.
- `EffectActuatorComponent` applies effects; `StatusComponent` tracks active statuses.

### UI System
- Screens extend `ui/screen.gd`; the coordinator is `ui/ui_layer.gd`.
- Use `%UniqueNodeName` syntax to reference nodes inside scenes.
- Signals drive all UI ↔ game logic communication.

## Directory Map
```
actor/          Base Actor, Unit, Enemy, Tower classes
autoload/       Global, SkillManager, Online, OnlineMatch singletons
behavior/       Rule-based AI (actions/, conditions/, target_selection/)
character/      Hero definitions (.tres) and base_character scene
components/     All component scripts and scenes
effects/        Relics, statuses, effect definitions
enemies/        Enemy type scenes and configs
enum.gd         Shared enums (import everywhere)
constants.gd    Global constants
game_logic/     Damage types, attack types, attributes
levels/         Level scenes and logic
run/            Run/campaign state
save/           Save state serialization
skill_tree/     Skill resources and trees
spawners/       Portal / wave spawners
tests/          GUT unit & integration tests
ui/             All UI screens and HUD (40+ scenes)
util/           StateMachine, TreePauser, Utils
```

## Common Tasks

**Add a new enemy type:**
1. Create a scene extending `enemies/base_enemy.tscn`
2. Add a `.tres` config resource (see `enemies/orc_warrior/orc_warrior.tres` as reference)
3. Embed the `StoredBehavior` inline in the `.tscn` or `.tres` config — there is no separate behavior resources directory
4. See `enemies/ENEMIES.md` for the current roster, stats, and behavior of all existing enemy types

**Enemy design principle:** each enemy type has a single fixed behavior that is consistent across every level it appears in. Players learn enemy patterns over time. Level difficulty comes from enemy *composition* (which types appear together, in what numbers and timing), not from per-level behavior changes.

**Add a new skill/action:**
1. Create a script in `behavior/actions/` extending the base action class
2. Register it in `SkillManager` / relevant skill tree `.tres`

**Add a new status/relic:**
1. Create a `status_def.gd` / `relic_def.gd` subclass
2. Save as `.tres` and add to `status_library.tres` / `relic_library.tres`

**Add a new UI screen:**
1. Create scene extending `ui/screen.gd`
2. Register transitions in `ui/ui_layer.gd`

## Physics Layers
| Layer | Name |
|-------|------|
| 1 | Entities |
| 2 | Actions |
| 3 | Hurtbox |
| 4 | Obstacles |

## Testing
Uses [GUT](https://github.com/bitwes/Gut). Tests live in `tests/`. Run via the GUT panel in the Godot editor or `gut` CLI.

## Autoloads (always available)
- `Global` — minimal globals (subviewport ref)
- `SkillManager` — skill lookup and restoration
- `Online` / `OnlineMatch` — Nakama multiplayer state
- `Nakama` — Nakama SDK entry point
