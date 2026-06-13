# Defense — Agent Guide

## Agent Rules (User Preferences)
Please always ask the user before:
* choosing a task
* writing code they didn't explicitly ask you to write
* calling a significant number of tools to perform research they haven't explicitly asked for

**Communication & Architectural Principles:**
* **Don't patch symptoms with architectural hacks:** If a test or edge case fails, do not add hacks to core logic just to make it pass. Analyze the root cause and respect established architectural boundaries (e.g., layer responsibilities and lifecycles).
* **Don't act unilaterally when corrected:** If the user points out a mistake, stop and discuss the problem. Do not silently run commands (like `git restore`) or modify files to fix it before getting explicit alignment.
* **Prioritize alignment over velocity:** It is always better to pause and discuss an analysis than to rush an incorrect implementation.

## Project Overview
A roguelike tower-defense game in **Godot 4.7**. Players select heroes, place them in levels, and survive enemy waves. Between levels, they unlock skills that modify hero behaviors. Supports local and online (Nakama) multiplayer.

## Read directory docs before reading code

Many subsystems have their own markdown docs that explain how things work without making you re-derive them from source. **Read the relevant doc first**, then dive into code only for the details the doc doesn't cover.

Subsystem docs:
- **`behavior/BEHAVIOR.md`** — rule-based AI: stored vs runtime split, param system, action lifecycle, adding new skills/params.
- **`enemies/ENEMIES.md`** — current roster + per-enemy stats + behavior.
- **`enemies/NEW_ENEMY.md`** — how to add a new enemy type.
- **`levels/LEVEL.md`** — stage-vs-level split and level registration.
- **`levels/CAMPAIGN_DESIGN.md`** — designing a set of levels (read first when planning >1 level).
- **`levels/STAGE_DESIGN.md`** — designing a new stage (terrain).
- **`levels/STAGE_BUILDING.md`** — assembling a stage's ground/zones/decoration.
- **`levels/SPRITESHEET_WORKFLOW.md`** — turning art into usable props/tiles.
- **`levels/LEVEL_DESIGN.md`** — designing a level on top of an existing stage; the 3-mode sim protocol.
- **`tools/sim/SIM.md`** — headless sim runner: config schema, behavior schema, summary schema, `diff.py` / `events.py` helpers.
- **`tools/sim/SIM_FINDINGS.md`** — game-side findings from sim sessions; add to it as you discover.
- **`BALANCE.md`** — global balance notes.
- **`game_logic/README.md`** — damage types, attack types, attributes.

Per-stage and per-level notes are colocated with the scenes:
- **`levels/stages/STAGE_NOTES_*.md`** — geometry, supports/does-not-support, tactical demands, quirks.
- **`levels/main/<stage>/LEVEL_NOTES_*.md`** — per-level intent, composition, verification status, quirks.

Convention: when you create a new stage or level, write a sibling `STAGE_NOTES_*.md` / `LEVEL_NOTES_*.md`.

## Key Architecture Patterns

### Component System
All game actors (`Actor` base class) are built from components. To find a component on a node:
```gdscript
var vitals = Component.get_or_null(actor, VitalsComponent.component)
# or, when it must exist:
var vitals = Component.get_or_die(actor, VitalsComponent.component)
```
Components have `run()` / `stop()` lifecycle methods. Never call component logic before `run()`.

### State Persistence (Unpack/Repack)
Avoid using stateful, persistent components attached to actors during gameplay. Instead, enforce clean boundaries between runs and levels:
- **Before a level (Unpack):** Create the `Character` scenes from the `GameplayCharacter` resource (via `CharacterSceneManager`), unpacking necessary persistent state (like health and relic state) into local runtime components (e.g., `EffectActuatorComponent`, `AttributesComponent`).
- **During a level:** All state mutations happen on the local runtime components of the `Character`.
- **After a level (Repack):** The `Level` script queries the local components (`extract_relic_state()`, `get_health()`) and writes the updated values back into the persistent `GameplayCharacter` resource before proceeding to the next stage.

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

#### Core design intent: behaviors are *player-authored, per-situation*

This is the heart of the game and easy to get wrong: **there is no single "correct" behavior per character.** The player is expected to tweak their hero behaviors based on:
- **Party composition** — a Knight + Priest run wants different behaviors than Wizard + Priest.
- **Level / stage** — corridor levels reward different priorities than open arenas; ranged-enemy levels need different positioning than melee-only.
- **Relics & acquired skills** — a hero with Hallowed Vestments or a new AoE skill rewrites the optimal rule set.

The **substrate** (conditions, targets, sorts, actions, primitives like `Targeting Tower` / `Can Hit Enemies` / `Targeted By Enemies` / `Preferred Target`) is the player's *toolkit*. The job of design work is to **make the substrate rich and composable enough** that for any reasonable party + level + relic combination, there exists *some* set of rules the player can author that beats it.

What this means in practice when working on this codebase:

- **Don't try to write one canonical behavior per character** and make it work everywhere. That's the wrong goal — and over-investing in it actively harms design (you'll start building anti-features to compensate for cases that should just need different rules).
- **Behaviors in `tools/sim/behaviors/`** are *test fixtures*, not products. They demonstrate "here's one set of rules that beats this scenario with this party." Naming them after what they *do mechanically* (`bernie_kite_and_commit`, `knight_commit_and_charge`, `cleric_aoe_heal_follow`, `bernie_with_armor_support`) is correct; naming them as "the" or "default" or "substrate" behavior is wrong.
- **When a level + party feels impossible**, the first question is "does the substrate let the player express a rule structure that would beat it?" — not "let's bake the solution into a behavior file." If the answer is no, the substrate is incomplete; build the missing primitive (a new condition, a new sort, a new action property). If the answer is yes, the level is correctly hard.
- **Sim configs** prove specific (party, level, behavior) combinations work. Use them as design regression tests, not as definitive AI files.

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

## Coding conventions

**Compare resources by reference, not by name.** When checking what a Resource IS (a damage type, status, skill, relic, etc.), `preload` the canonical `.tres` and compare by identity:

```gdscript
const fire_damage_type = preload("res://game_logic/damage_types/fire.tres")

func modify_hit_effect(hit_effect: HitEffect, _target: Node, _logger: Callable) -> void:
    if hit_effect.damage_type == fire_damage_type:   # ✓ identity
        ...
```

**Deep-Copying Dictionaries:** When deep-copying complex dictionaries (especially those that might hold Resources), always use Godot's native `duplicate_deep()` method.
```gdscript
# Correct:
var cloned_state = state.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)

# Incorrect (Does not deep-copy resources properly):
var cloned_state = state.duplicate(true)
```

Not:

```gdscript
const FIRE_NAME: StringName = &"Fire"
if hit_effect.damage_type.name == FIRE_NAME:        # ✗ stringly-typed; renames break silently
    ...
```

This applies even when the field on hand is *just* a `StringName` — preload the canonical resource and pull the name off it. E.g. `HitEffect.action_name` is a `StringName` with no `ActionDef` reference attached, but you can still do:

```gdscript
const sword_attack_def = preload("res://skill_tree/actions/sword_attack.tres")
if hit_effect.action_name != sword_attack_def.skill_name:
    return
```

A renamed skill flows through the def automatically; nothing in your relic needs an update.

## Physics Layers
| Layer | Name |
|-------|------|
| 1 | Entities |
| 2 | Actions |
| 3 | Hurtbox |
| 4 | Obstacles |

## Designing Levels, Stages, Campaigns

Three layered design docs in [`levels/`](levels/) — read the relevant one before authoring content:

- **[CAMPAIGN_DESIGN.md](levels/CAMPAIGN_DESIGN.md)** — methodology for designing a SET of levels (the 10-fight backbone, the aspirational run shape, class-comp constraints, build-order strategy). Read first if you're planning more than one level at a time. Also contains the critical four-way distinction between *starting unlocked* / *current unlocked* (both global per-save) and *initial kit* / *current kit* (per-character per-run) skill sets — read that section before touching any code that says `skills`, `acquired_skills`, or "unlocked," and note the dual-duty quirk in `Constants.base_acquired_skills`.
- **[STAGE_DESIGN.md](levels/STAGE_DESIGN.md)** — playbook for designing a new stage (terrain). 5 design questions + verification protocol + the `.tscn` script-UID gotcha that bites hand-authoring.
- **[LEVEL_DESIGN.md](levels/LEVEL_DESIGN.md)** — playbook for designing a single level on top of an existing stage. 4 design questions + spawner `.tscn` pattern + the 3-mode sim verification (A feasibility, B robustness, C progression).

Two more docs cover building a stage's **visuals** (terrain + decoration), distinct from its gameplay design:

- **[SPRITESHEET_WORKFLOW.md](levels/SPRITESHEET_WORKFLOW.md)** — turning a raw art spritesheet into usable assets (prop scenes / registered TileSet terrains). Phase A tiling → Phase B preview verify → ToC → generate. Work from JSON, not eyeballing.
- **[STAGE_BUILDING.md](levels/STAGE_BUILDING.md)** — assembling a stage's ground + zones + decoration. The `Zone` model (OPEN/ENCLOSED/SOLID), `GroundPainter`, `DecorationScatter`, and the `audit_zones.gd` coverage check.

Game-side findings from sim sessions live in [`tools/sim/SIM_FINDINGS.md`](tools/sim/SIM_FINDINGS.md); add new findings there as you discover them.

The simulator itself: [`tools/sim/SIM.md`](tools/sim/SIM.md).

## Godot binary

`/data/godot/bin/` contains the available Godot versions. In general there will be only one available — invoke it directly (no `godot` on `$PATH` by default). If there is more than one, ask the user which to use and commit that choice to memory so future sessions don't keep asking.

## Testing
Uses [GUT](https://github.com/bitwes/Gut). Tests live in `tests/`. Run via the GUT panel in the Godot editor or `gut` CLI.

## Dependency Cycle Check
Circular dependencies in Godot can lead to compilation issues and hard-to-debug runtime crashes. A Python tool set is provided in the project root to detect cycles.

**Before declaring any job done, you MUST run this check to ensure you haven't introduced any cycles:**
```bash
python3 deps.py . && python3 dot_find_cycles.py Digraph.gv
```
- `deps.py` parses class references and outputs `Digraph.gv`.
- `dot_find_cycles.py` reads `Digraph.gv` and prints all detected cycles.

### Rules for Cycle Resolution:
1. **NO type weakening/removal**: Do not remove type annotations or replace concrete class types with generic types (like `Resource` or `Node`) solely to bypass the dependency checker. Type annotations must remain strong and accurate.
2. **NO load-based hacks**: Do not replace static `preload` references with runtime `load` calls just to evade detection, unless there is a clear, explicit gameplay/architectural requirement for dynamic runtime loading.
3. **Use Event-driven architecture / Signals**: Decouple components using signals and events so caller scripts do not need static type annotations for concrete callee types.
4. **Ignored sections for standalone/debug code**: Explicitly mark standalone editor/debug code sections with `# ignore-dep` (which the updated `deps.py` will skip).

## Autoloads (always available)
- `Global` — minimal globals (subviewport ref)
- `SkillManager` — skill lookup and restoration
- `Online` / `OnlineMatch` — Nakama multiplayer state
- `Nakama` — Nakama SDK entry point
