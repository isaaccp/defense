# LEVEL_NOTES: 04_orc_horde

**Position in campaign:** stage 4 (difficulty 4).

**Intent:** Test player split attention and pocket pivot tempo. A front corridor assault of Grunts and Warriors pressures player characters. At t=12s and t=14s, Orc Archers and Orc Shamans spawn directly in the vertical pocket above the tower/StartingPositions. If players ignore the pocket, the Archers will shred the tower while Shamans heal the pocket team and the main line. The player must split focus or pivot.

## Composition

| Slot | Value |
|---|---|
| Stage | `forest_ambush.tscn` |
| Enemies | 8 Orc Grunts, 4 Orc Warriors, 3 Orc Archers, 2 Orc Shamans |
| Spawner position | Grunts & Warriors @ (650, 260) (Main)<br>Archers & Shamans @ (250, 100) (Pocket) |
| Spawn timing | Grunt: `amount=8, interval=1.5, initial_delay=1.0`<br>Warrior: `amount=4, interval=3.0, initial_delay=5.0`<br>Archer: `amount=3, interval=2.0, initial_delay=12.0`<br>Shaman: `amount=2, interval=4.0, initial_delay=14.0` |
| Tower | inherited 200 HP from stage |
| Victory/loss | inherited from base (KILL_ALL_ENEMIES / ALL_CHARACTERS_DIED + TOWER_DIED) |

## Substrate assumptions

Requires player meta-skills (e.g. `Target Near Tower` or priority targeting) to pivot characters back to protect the tower from the pocket flankers, who appear directly adjacent to the defense area.

## Tactical demands

* **Pocket pivot**: Pivoting to target flankers in the pocket area is critical.
* **Cover usage**: The top forest blocks LoS from the pocket to the far corridor, necessitating close engagement.
