# Enemies

All enemies use the same behavior engine as player characters. Each enemy type has a fixed behavior that is consistent across all levels it appears in — players can learn and rely on these patterns.

All enemies are instantiated using the generic [enemy.tscn](file:///data/godot/games/defense/enemies/enemy.tscn) scene and populated via their `.tres` configuration resources.

## Current Enemy Roster

### Orc Grunt
**File:** `orc_grunt/orc_grunt.tres`

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
**File:** `orc_warrior/orc_warrior.tres`

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
**File:** `orc_archer/orc_archer.tres`

| Stat | Value |
|------|-------|
| HP | 5 |
| Speed | 30 |
| Armor | 0 |

**Behavior (in priority order):**
1. Always → Bow Attack → closest Enemy (min range 100, max range 300, ranged/piercing, 3 piercing damage)
2. Always → Move Away (max 120) → closest Enemy — flees when target closes within 120
3. Always → Move To → closest Enemy

Kiting ranged attacker. Fires from distance, backs away when an enemy enters 120 units, and closes in if no target is in range. The min_distance=100 on the bow ensures it won't fire point-blank while retreating.

---

### Orc Berserker
**File:** `orc_berserker/orc_berserker.tres`

| Stat | Value |
|------|-------|
| HP | 8 |
| Speed | 45 |
| Armor | 0 |

**Behavior (in priority order):**
1. Always → Charge → closest Enemy (min range 50, cooldown 4s — gains Swiftness; triggers Strength Surge if charged ≥ 100 units)
2. Always → Sword Attack → closest Enemy (range 40, melee, 5 slashing damage)
3. Always → Move To → closest Enemy

Fastest enemy in the roster. Charges from range, briefly becoming even faster and dealing bonus damage if the charge covered enough ground. Once in melee, follows up with a sword attack. The 4s charge cooldown means it can't chain charges back-to-back.

---

### Skeleton Warrior
**File:** `skeleton_warrior/skeleton_warrior.tres`

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
**File:** `skeleton_mage/skeleton_mage.tres`

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

### Orc Shaman
**File:** `orc_shaman/orc_shaman.tres`

| Stat | Value |
|------|-------|
| HP | 8 |
| Speed | 30 |
| Armor | 0 |

**Behavior (in priority order):**
1. Target Health < 15 → Heal → Self Or Ally (heals 15 HP, cooldown 3s, range 200, lowest health first)
2. Always → Seeking Bolt → closest Enemy (min range 100, max range 300, 5 arcane damage, homing)
3. Always → Move To → closest Enemy

Support enemy type. Focuses on keeping other Orc frontliners healthy by casting Heal, and uses Seeking Bolt from range if no allies need healing.

---

## Notes on Current State

- Most enemies target the **closest enemy** with no other priority logic, though support enemies like the Orc Shaman target allies by lowest health.
- The Orc Shaman is the first enemy with conditional behavior, healing allies when their HP falls below 15.
- The Skeleton Warrior and Skeleton Mage are fully implemented but absent from main level content.
- All enemies share the same Move To fallback when their primary action is out of range or on cooldown.
- The Orc Archer is the only enemy that actively maintains distance (kiting behavior).
