# LEVEL_NOTES: 04_shaman_chokepoint

**Position in campaign:** stage 4 (difficulty 4).

**Intent:** Introduce the Orc Shaman supporting melee combatants in a narrow corridor. Test player prioritization: if player characters attack closest target, Orc Warriors absorb damage while Orc Shamans stay back and heal them, leading to combat attrition. Players must either use AoE skills (Cleave, Sweeping Attack, Holy Nova) to damage the group, use ranged characters to target Shamans directly, or position carefully.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_chokepoint.tscn` |
| Enemies | 6 Orc Warriors, 4 Orc Berserkers, 3 Orc Shamans |
| Spawner position | Warrior & Berserker spawners @ (900, 260), Shaman spawner @ (920, 260) |
| Spawn timing | Warrior: `amount=6, interval=3.5, initial_delay=1.0`<br>Berserker: `amount=4, interval=4.0, initial_delay=6.0`<br>Shaman: `amount=3, interval=6.0, initial_delay=8.0` |
| Tower | inherited 200 HP from stage |
| Victory/loss | inherited from base (KILL_ALL_ENEMIES / ALL_CHARACTERS_DIED + TOWER_DIED) |

## Substrate assumptions

Requires player meta-skills and acquired skills (e.g. Cleave/Sweeping Attack/Holy Nova or preferred target behaviors) to handle healing attrition. Standard starting-kit simple behaviors may lose due to Warriors being continuously healed by Shamans.

## Tactical demands

* **Priority shifting**: Healer shaman must be cleared or out-damaged.
* **AoE clustering**: Funneling in the 130px corridor clusters Warriors, Berserkers, and Shamans close together, rewarding AoE skills.
