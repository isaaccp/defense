# BALANCE.md

Cross-cutting reference of every knob that affects run difficulty, class identity, or pacing. Use this before a balance pass so you don't tweak one knob in isolation while a neighboring knob silently undoes the change. If you add a new balance lever, **add it here** — knobs that aren't listed here tend to become invisible (see "recovery" history).

For level-specific tuning (spawner counts, intervals, enemy mix) see [LEVEL_DESIGN.md](levels/LEVEL_DESIGN.md). This doc covers everything *outside* a single level.

---

## 1. Per-character

Defined on `Attributes` ([game_logic/attributes/attributes.gd](game_logic/attributes/attributes.gd)) — one resource per character at [character/playable_characters/](character/playable_characters/).

| Knob | Effect | Notes |
|---|---|---|
| `speed` | Movement speed | Class identity. Rogue/Wizard fast, Knight slow. |
| `health` | Max HP | Class identity. Don't double-dip with `recovery`. |
| `recovery` | Post-level heal as fraction of max HP | **Flat default on `Attributes`** (currently 0.25). Don't override per-char without explicit design reason — multiplies with `health` and produces silent imbalance. |
| `focus` | Max focus | Caps the burst capacity of a class. |
| `focus_regen` | Focus per second | Baseline floor 0.5 for non-Knight. Knight is fed by Defiance instead. |
| `health_regen` | In-combat HP per second | **Default 0.** Raised by relics like Regeneration Ring (+1.0/s). Mirrors `focus_regen` pattern in VitalsComponent. |
| `damage_multiplier` | Flat multiplier on all damage dealt | **Default 1.0 — do not override per-character.** Reserved for runtime effects (e.g. Strength Surge status, future damage-buff relics). Static per-class damage should be done via action damage values or a HIT_EFFECT relic, both visible to the player. |
| `armor` | Flat damage reduction (physical) | Knight 1. |
| `resistance` | Per-attack/damage-type % | Mostly relics raise this. |

**Class relics** (one per class, permanent, fund the class's focus identity):
- Knight: **Defiance** — +1 focus per HP damage taken ([effects/relics/defiance.gd](effects/relics/defiance.gd))
- Cleric: **Unyielding Hope** — +50% of HP healed → focus ([effects/relics/unyielding_hope.gd](effects/relics/unyielding_hope.gd))
- Rogue: **Killer's Edge** — +2 focus per kill ([effects/relics/killers_edge.gd](effects/relics/killers_edge.gd))
- Wizard: **Meditation** — +1.0/s focus_regen ([effects/relics/meditation.gd](effects/relics/meditation.gd))

**Starting bonus relics** (one per class, permanent, secondary identity — durability/capacity, separate from focus management):
- Knight: **Regeneration Ring** — +1 HP/s in combat ([effects/relics/regeneration_ring.gd](effects/relics/regeneration_ring.gd))
- Cleric: **Hallowed Vestments** — -50% damage from ranged attacks ([effects/relics/hallowed_vestments.gd](effects/relics/hallowed_vestments.gd))
- Rogue: **Killer's Insight** — +50% damage vs enemies <30% HP ([effects/relics/killers_insight.gd](effects/relics/killers_insight.gd))
- Wizard: **Arcane Battery** — +30 max focus ([effects/relics/arcane_battery.gd](effects/relics/arcane_battery.gd))

Future extension (per [NEXT_STEPS.md](NEXT_STEPS.md)): multiple starting bonus relics per class, with player choice at run start.

---

## 2. Actions

Per-action knobs on `Action` ([behavior/actions/action.gd](behavior/actions/action.gd)) set in each action's `_init()`:

| Knob | Effect | Typical range |
|---|---|---|
| `focus_cost` | Focus deducted on use | 0 (movement) to 4 (heavy spells) |
| `cooldown` | Seconds before reuse | 0 (basic attacks) to 15 (meditate) |
| `prepare_time` | Cast time before effect | Most damage actions are instant |
| `max_distance` / `min_distance` | Targeting range | Sets engagement zone |
| `abortable` | Can other rules preempt | Affects responsiveness |

Per-action **damage / heal amounts** live in each action's script (e.g. [behavior/actions/heal_action.gd](behavior/actions/heal_action.gd), [behavior/actions/sword_attack_action.gd](behavior/actions/sword_attack_action.gd)).

**Focus cost reference** (current values, see action `_init()` for source of truth):
- 0: move_to, move_away, meditate
- 1: sword_attack, bow_attack
- 2: seeking_bolt, heal, magic_armor, charge, blink_away, blink_to
- 3: cleave, sweeping_attack, projectile_ward
- 4: multi_shot, fire_burst, hold_person, teleport_away, teleport_to

If a new spell needs to be "always available," set `focus_cost = 0` and use cooldown as the gate. If it needs to be a "burn focus to win" cast, set it ≥3.

---

## 3. Enemies

Per-enemy `Attributes` lives on each enemy scene/resource at [enemies/](enemies/). Same fields as character attributes.

Current state: enemies have **placeholder** `focus = 100, focus_regen = 10.0` — focus is "never a constraint" for enemies. Eventual goal is tighter per-enemy focus (see `NEXT_STEPS.md` → Enemy Focus Tuning).

Per-enemy levers when tuning:
- `health` — primary durability knob
- `speed` — controls how much time players have to react
- `damage_multiplier`, `armor` — secondary
- behavior rules — non-numeric but huge (kiting archer vs. brain-dead grunt)

See [enemies/ENEMIES.md](enemies/ENEMIES.md) for the bestiary and [enemies/NEW_ENEMY.md](enemies/NEW_ENEMY.md) for adding one.

---

## 4. Encounter / level

Covered in detail by [LEVEL_DESIGN.md](levels/LEVEL_DESIGN.md). Summary table for cross-reference:

| Knob | Where | Highest leverage? |
|---|---|---|
| Spawner positions | level .tscn | Yes (geometry > everything) |
| `interval`, `amount`, `initial_delay` on spawners | level .tscn | Yes |
| Enemy mix per spawner | level .tscn | Yes |
| Placement zone | `PlacementComponent` | Yes — restricts player setup |
| Tower HP / position | level .tscn | Stage-defining |
| `base_xp` on `XPComponent` | level .tscn | Reward scaling |

Levels are validated via Mode A/B/C sim runs (see [LEVEL_DESIGN.md](levels/LEVEL_DESIGN.md)).

---

## 5. Economy & progression

| Knob | Where | Effect |
|---|---|---|
| `base_xp` (per level) | level .tscn `XPComponent` | Run-level XP grant |
| Time-bonus multipliers | [levels/components/xp_component.gd](levels/components/xp_component.gd) | 2x / 1.5x / 1x / 0.5x at 15s / 30s / 60s / >60s since last spawn |
| `meta_xp_per_level` | [run/run.gd:27](run/run.gd#L27) | Meta XP for skill tree unlocks |
| `Attributes.recovery` (default) | [game_logic/attributes/attributes.gd](game_logic/attributes/attributes.gd) | Post-level HP heal fraction. Flat across classes. |
| `base_acquired_skills` | [constants.gd](constants.gd) | Skills every character starts with at run start |
| Starting kit (per-character) | character .tres `acquired_skills` | Per-class run-start skill set |
| Relic drops / shop offerings | **NOT YET IMPLEMENTED** | Track in NEXT_STEPS |

---

## 6. Global constants

[constants.gd](constants.gd):
- `base_acquired_skills` — universal starting skills (Enemy, Ally, Tower, Move To, Closest First)

[run/run.gd](run/run.gd):
- `meta_xp_per_level = 50`

---

## How to use this doc

Before tweaking a knob, scan the table that contains it and ask:
1. **Does another knob already cover this?** (If you're raising Knight HP, are you also adjusting his `recovery`? Stop — flatten one of them first.)
2. **Is this a class-identity knob or a balance-baseline knob?** Identity knobs (`speed`, `focus_regen`, class relic) should differ between classes. Baseline knobs (`recovery`, action `cooldown`) should usually be flat unless there's a strong design reason.
3. **Is this knob doing class differentiation that a relic should be doing?** Relics are visible to the player; attributes are invisible. Prefer relics for any differentiation worth >5% impact.

When you add a new balance lever, add a row here. The cost of not documenting it is that future-you re-discovers it in a balance pass three months from now and wastes an afternoon working out interactions.
