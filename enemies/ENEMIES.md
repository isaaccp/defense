# Enemies

All enemies use the same behavior engine as player characters. Each enemy type has a fixed behavior that is consistent across all levels it appears in — players can learn and rely on these patterns.

## Current Enemy Types

### Orc Grunt
**File:** `orc_grunt/orc_grunt.tscn`

| Stat | Value |
|------|-------|
| HP | 6 |
| Speed | 35 |
| Armor | 0 |

**Behavior (in priority order):**
1. Always → Sword Attack → closest Enemy (range 40, melee, 5 slashing damage)
2. Always → Move To → closest Enemy

The weakest and fastest enemy. Will rush the nearest character and swing. Lowest health in the roster — intended as a swarming threat.

---

### Orc Warrior
**File:** `orc_warrior/orc_warrior.tres` (used via `enemy.tscn`)

| Stat | Value |
|------|-------|
| HP | 10 |
| Speed | 30 |
| Armor | 1 |

**Behavior (in priority order):**
1. Always → Sword Attack → closest Enemy (range 40, melee, 5 slashing damage)
2. Always → Move To → closest Enemy

Standard melee frontliner. Tougher than the grunt and slightly slower. The armor means physical attacks deal 1 less damage per hit. Identical behavior to the grunt but more durable.

---

### Orc Archer
**File:** `orc_archer/orc_archer.tscn`

| Stat | Value |
|------|-------|
| HP | 5 |
| Speed | 30 |
| Armor | 0 |

**Behavior (in priority order):**
1. Always → Bow Attack → closest Enemy (range 300, ranged/piercing, 3 piercing damage)
2. Always → Move To → closest Enemy

Fragile ranged attacker. Despite having a long-range attack, the archer does **not** maintain distance — it will walk toward the player if out of range, and does not flee when approached. (There is a commented-out `min_distance = 100` in `bow_attack_action.gd` that would make archers kite, but it is currently disabled.)

---

### Skeleton Warrior
**File:** `skeleton_warrior/skeleton_warrior.tscn`

| Stat | Value |
|------|-------|
| HP | 8 |
| Speed | 30 |
| Armor | 2 |

**Behavior (in priority order):**
1. Always → Sword Attack → closest Enemy (range 40, melee, 5 slashing damage)
2. Always → Move To → closest Enemy

The most physically resilient frontliner — armor 2 makes physical attacks hit significantly less hard. Behavior is identical to the Orc Warrior. **Not currently used in any main level.**

---

### Skeleton Mage
**File:** `skeleton_mage/skeleton_mage.tscn`

| Stat | Value |
|------|-------|
| HP | 6 |
| Speed | 28 |
| Armor | 0 |

**Behavior (in priority order):**
1. Always → Seeking Bolt → closest Enemy (min range 100, max range 300, magical/arcane, 5 arcane damage, homing)
2. Always → Move To → closest Enemy

Slowest enemy in the roster. Fires a homing bolt that tracks its intended target. Has a minimum range — will close distance if the target is closer than 100 units, but otherwise prefers to stay back and fire. **Not currently used in any main level.**

---

## Notes on Current State

- Every enemy targets the **closest enemy** with no other priority logic.
- No enemy has conditional behavior (e.g., reacting to low HP, targeting healers, grouping up).
- The Skeleton Warrior and Skeleton Mage are fully implemented but absent from main level content.
- All enemies share the same Move To fallback when their primary action is out of range or on cooldown.
