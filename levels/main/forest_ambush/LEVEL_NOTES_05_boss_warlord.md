# LEVEL_NOTES: 05_boss_warlord

**Position in campaign:** stage 5 (difficulty 5 - Boss Stage).

**Intent:** The final challenge of the forest campaign. Introduce **Gruul the Orc Warlord** boss. Test player's ability to deal with a highly resilient frontline boss who taunts players away from the tower, coupled with a flanking distraction of high-ground Archers in the pocket, and a group of elite Warlord Guards who receive a massive Haste buff from the boss's Battle Cry.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_ambush.tscn` |
| Enemies | 4 Orc Grunts, 2 Orc Warriors, 2 Orc Berserkers, 1 Orc Warlord (Boss), 3 Orc Warriors (Warlord Guards), 2 Orc Archers (Pocket) |
| Spawner position | Main Wave: (650, 260) (Main Portal)<br>Pocket Wave: (250, 100) (Pocket) |
| Spawn timing | Grunt: `amount=4, interval=1.5, initial_delay=1.0`<br>Warrior: `amount=2, interval=2.0, initial_delay=4.0`<br>Berserker: `amount=2, interval=3.0, initial_delay=8.0`<br>Warlord: `amount=1, interval=1.0, initial_delay=15.0`<br>Warlord Guards (Warrior): `amount=3, interval=2.0, initial_delay=15.0`<br>Archer: `amount=2, interval=2.0, initial_delay=17.0` |
| Tower | inherited 200 HP from stage |
| Victory/loss | inherited from base (KILL_ALL_ENEMIES / ALL_CHARACTERS_DIED + TOWER_DIED) |

## Substrate assumptions

Requires players to have acquired advanced rules/skills (e.g. Wizard's `Frost Nova` or `Chilling Sphere` to crowd-control and slow down the hasted guards, and Cleric/Knight using protective rules to defend the tower from the pocket archers while the boss taunts them).

## Tactical demands

* **Haste Mitigation**: The Warlord's Battle Cry buffs himself and his guards with Haste. Slighting or crowd-controlling the guards (e.g. with Frost Nova freeze) is crucial.
* **Pocket Disruption**: The pocket Archers spawn right next to the tower and will chip it down if ignored, requiring targeted ranged action or careful Cleric healing support.
* **Taunt Recovery**: The Warlord's Taunt forces heroes to focus him, which can drag them out of position. Defensive buffers or strong single-target DPS are required to survive.
