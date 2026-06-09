# Behavior System

Each actor (player character or enemy) runs a **Behavior**: an ordered list of Rules evaluated every physics frame. The first rule whose condition passes and whose action can execute on a valid target wins.

## Two-Layer Design

There is a clean split between the **serializable/stored** layer and the **runtime** layer.

| Stored (saved to disk) | Runtime (instantiated per-actor) |
|---|---|
| `StoredBehavior` | `Behavior` |
| `RuleDef` | `Rule` |
| `StoredParamSkill` / `StoredSkill` | `ActionDef` / `ConditionDef` / `TargetSelectionDef` |

`SkillManager.restore_rule(rule_def)` converts a `RuleDef` into a `Rule` by looking up each skill by name, cloning it, and copying the stored params onto the clone. The runtime objects are never saved.

## Skill Types

All skills live in `skill_tree/` and are registered in collections under `skill_tree/skill_type_collections/`. `SkillManager` loads these on startup and indexes them by name.

| Type | Class | Collection | Purpose |
|---|---|---|---|
| Action | `ActionDef` (extends `ParamSkill`) | `action_collection.tres` | What the actor does |
| Condition | `ConditionDef` (extends `ParamSkill`) | `condition_collection.tres` | When the rule is eligible |
| Target | `TargetSelectionDef` (extends `ParamSkill`) | `target_collection.tres` | Who/what to act on |
| Target Sort | `TargetSort` (extends `Skill`) | `target_sort_collection.tres` | How to rank multiple candidate targets |

Target sorts are stateless and non-parameterizable; all others can carry params.

## The Param System

`SkillParams` holds optional typed values that configure a skill per-usage:

- `cmp: CmpOp` — comparison operator (LT, LE, EQ, GE, GT)
- `int_value: IntValue`
- `float_value: FloatValue`
- `sort: StoredSkill` — a target sort (requires restoration, see below)

`editor_string` is a template like `"Enemy (HP {cmp} {int_value}%)"` that drives UI display. Only placeholders that appear in `editor_string` are active.

**Stored params** live on `StoredParamSkill.params`. During `SkillManager.restore_skill()`, these are copied onto the cloned skill (`skill.params = stored_skill.params`). The `sort` placeholder needs an extra resolution step: the stored `StoredSkill` is resolved to a live `TargetSort` instance and placed in `skill.restored_skill_params.sort`.

**Accessing params at runtime:**
- Actions: read `self.def.params` inside `post_initialize()` or later. `def` is set before `initialize()` is called.
- Target selectors: read `self.def.params` / `self.def.restored_skill_params.sort`.
- Conditions: same pattern.

## A Rule in Full

```
RuleDef
  ├── condition: StoredParamSkill      → ConditionDef  (when)
  ├── target_selection: StoredParamSkill → TargetSelectionDef (who)
  └── action: StoredParamSkill         → ActionDef     (what)
```

`Rule` (runtime) holds the resolved `ConditionDef`, `TargetSelectionDef`, `ActionDef`.

## BehaviorComponent Runtime Loop (every physics frame)

1. If the current action is finished, clear it and reset `rule`.
2. If no rule is active (or the action is `abortable` and the check interval has elapsed), call `behavior.choose(action_cooldowns, elapsed_time)`.
3. `choose()` iterates rules in priority order:
   - Skip if action is on cooldown.
   - Skip if condition evaluator returns false.
   - Skip if actor lacks enough focus.
   - Ask the target selector for a valid target.
   - First rule that passes all checks wins. Returns `{id, rule, target, action}`.
4. If the chosen rule/target differs from what's running, the current action is preempted (`action.action_finished()`) and the new action is initialized.
5. `action.physics_process(delta)` runs the active action each frame.

## Action Lifecycle

```
make_runnable_action(def)   # creates instance, sets action.def, calls post_make()
    ↓
post_make()                  # override to apply param-driven properties (e.g. max_distance
    ↓                        # from float_value) — def is set, but no actor/target yet
initialize(target, actor, …) # sets all deps; calls post_initialize() deferred
    ↓
post_initialize()            # start async work, set up navigation, etc.
    ↓
[if prepare_time > 0]
post_prepare()               # fire projectile, swing sword, etc.
    ↓
action_finished()            # marks finished=true; cooldown recorded by BehaviorComponent
```

**Key action properties** (set in `_init()`):
- `min_distance` / `max_distance` — range within which the action is valid for a target
- `cooldown` — seconds before the action can be chosen again
- `focus_cost` — focus consumed on execution
- `abortable` — if true, a higher-priority rule can preempt this action mid-execution
- `filter_with_distance` — if true, distance filtering scans all candidates (good for Move To alternatives); if false, it picks one candidate first then distance-checks it (good for Move To, so it doesn't switch to a farther enemy just because the nearest is too close)
- `finish_on_unmet_condition` — action self-terminates if the triggering condition stops being true (used by Move Away)
- `need_valid_target_after_prepare` — action aborts if target dies during prepare phase (used by Seeking Bolt)

## Condition Types

`ConditionDef.Type` controls what the condition can be checked against:

- `ANY` — no target needed (e.g. "Once")
- `SELF` — checked against the actor itself (e.g. "self HP < 50%")
- `TARGET_ACTOR` — filters actor targets (e.g. "target HP < 50%")
- `TARGET_POSITION` — applies to position or actor targets
- `GLOBAL` — world-level checks (not yet implemented)

`ConditionEvaluatorFactory` creates the right evaluator subclass based on the condition type and wires in the actor reference.

## Available Skills

**Actions:** Blink Away, Blink To, Bow Attack, Charge, Cleave, Fire Burst, Heal, Hold Person, Magic Armor, Meditate, Move Away, Move To, Multi Shot, Projectile Ward, Seeking Bolt, Sweeping Attack, Sword Attack, Teleport Away, Teleport To

**Conditions:** Once, Self, Target Distance, Target Health, Times. A rule with no conditions fires unconditionally — there is no longer a separate "Always" skill.

**Targets:** Ally, Center, Enemy, Self Or Ally, Tower

**Target sorts:** Closest First, Farthest First

Skills are referenced by StringName (e.g. `&"Sword Attack"`) in `StoredParamSkill` resources. The authoritative source is the `.tres` files in `skill_tree/actions/`, `skill_tree/conditions/`, `skill_tree/targets/`, and `skill_tree/target_sorts/`.

## Adding a New Skill

**New Action:**
1. Write `my_action.gd` extending `Action` (or a base like `ProjectileAttackActionBase`).
2. Create `skill_tree/actions/my_action.tres` as an `ActionDef` resource, pointing to the script and listing `supported_target_types`.
3. Add it to `action_collection.tres`.
4. Reference it by name (`&"My Action"`) in any `StoredParamSkill`.

**New Condition / Target:** same pattern with `ConditionDef` / `TargetSelectionDef` and their respective collections.

**New configurable param on an existing action:**
- Add the placeholder to the action's `editor_string` in its `.tres` file (e.g. `"{float_value}"`).
- Read it in the action via `def.params.float_value.value` (check `def.params.placeholder_set(...)` first).
- Per-usage values are set on the `StoredParamSkill.params` in the behavior `.tscn` or saved behavior resource.
