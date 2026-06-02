# Campaign Design Methodology

How we're approaching the design of a coherent **set of levels** (a run, eventually a Slay-the-Spire-style branching campaign). Built around what's currently achievable + what we're aspirationally targeting.

For per-level design see [LEVEL_DESIGN.md](LEVEL_DESIGN.md); for stage geometry see [STAGE_DESIGN.md](STAGE_DESIGN.md). This doc is the **tier above** those — it answers "how do these levels relate to each other?"

## Vocabulary: the four skill sets

Critical distinction — these get conflated and produce nonsense if mixed up. At any point in time **four** skill sets are in play. Two are **global per-save** (apply to all characters in the run); two are **per-character per-run**.

| Term | What it is | Scope | Where it lives in code | Changes via |
|---|---|---|---|---|
| **Starting unlocked skills** | The unlocked set seeded into a brand-new save | Global (one set, shared by every character in a run) | Built in `main.gd::load_save_state()` for a new save: `Constants.base_acquired_skills` ∪ ⋃(`gc.acquired_skills.skills` for `gc` in `level_provider.available_characters`) — i.e. the universal baseline plus every character's initial kit. Stored on `SaveState.unlocked_skills`. | Game updates that change starting kits or `base_acquired_skills` |
| **Current unlocked skills** | The unlocked set at this point in meta-progression (starting unlocked + anything earned across runs) | Global per-save | `SaveState.unlocked_skills`; grown by `main.gd` calling `mark_available()` | Cross-run meta-progression (defeating bosses, achievements, etc.) |
| **Initial character kit (initial acquired skills)** | The skills a specific character starts a *single run* with — the "you are a knight, you get sword+move" identity | Per-class, per-run (constant within a run) | Character `.tres` `acquired_skills.skills`, PLUS `Constants.base_acquired_skills` auto-added in `gameplay_character.gd::initialize()` | Run start |
| **Current character kit (current acquired skills)** | The character's skills at any point *during* a run — initial kit plus anything acquired so far (level-up picks, random skill offerings, relics) | Per-character, per-moment | `GameplayCharacter.acquired_skills` (mutated as the run progresses) | Mid-run progression |

**Relationship**: `initial kit` ⊆ `current kit` ⊆ `current unlocked` ⊆ everything in the skill tree. `starting unlocked` is what `current unlocked` was at save-creation time.

**Implication of starting unlocked being a union of all starting kits**: any skill in ANY class's starting kit is automatically unlocked save-wide for everyone. If the wizard starts with `Seeking Bolt`, the knight can acquire `Seeking Bolt` mid-run (subject to whatever pick/cost rules apply) on the same save. Adding a skill to a starting kit therefore changes both:
1. That class's identity (initial kit)
2. The universal unlocked pool (starting unlocked, for new saves)

`Constants.base_acquired_skills` has a separate dual role: it both seeds starting unlocked AND is auto-added to every character's `acquired_skills` in `initialize()`. So changing that constant affects "what every character has from t=0 in any run" as well as the unlocked pool.

When you read `acquired_skills` in a sim config, that's the **current kit** at the moment of that simulated fight (the player has "acquired" these skills by the time this fight starts).

### Design direction (near-term content task)

**Starting unlocked should eventually cover all skills currently in the tree** — we want a big pool of unlockable skills, so a brand-new player picking up the game has all current content available to acquire mid-run via XP/offerings/etc. Meta-progression then adds NEW skills as the tree expands beyond what's currently in any starting kit.

Two natural paths, given the implication above:

- **Path A: bump starting kits.** As we expand each class's starting kit (the near-term task), every added skill becomes universally unlocked as a side effect via the union in `load_save_state`. This is enough to cover any skill that's thematically reasonable for SOME class to start with. Skills that are intentionally "advanced" (no class starts with them) stay locked behind meta-progression — which is a feature, not a bug.
- **Path B: independent expansion.** If we want starting unlocked to include skills that NO class starts with (intentionally advanced or weird), add them explicitly — either by extending the `load_save_state` seed loop, adding to `Constants.base_acquired_skills`, or introducing a new `Constants.starting_unlocked_skills`. None are needed yet.

Path A is sufficient for the near-term work — bumping starting kits naturally expands the unlocked pool.

**Initial kits should grow modestly** from current values: Knight 8 / Cleric 10 / Rogue 5 / Wizard 5 → roughly 10 each, so the run feels agentful from fight 1 regardless of class. As noted, this also expands starting unlocked.

## Target run shape (aspirational)

- **3 maps × ~15 min ≈ 45 min per run.** A map is ~15 min of play (3-5 fights + non-combat nodes).
- **Slay-the-Spire-style branching maps:** fight nodes + rest points + chests (relics) + events. Player chooses path through the map.
- **Linear ramp difficulty** within and across maps; later maps harder than earlier.
- **Always able to retry** a fight; "Abandon Run" lets the player exit a doomed run.
- **Roguelike meta-progression** — between runs, players unlock new skills, new starting kits, possibly new mechanics (e.g. Behavior Library, enemy log inspection as meta-skill unlocks). Bigger "unlocked but not acquired" pool means experienced players can theoretically beat the game on first try, but extra unlocks make it easier.

## Current scope (what we're actually building)

- **10-fight linear sequence** — roughly 2 maps' worth of fight content, no branching, no rest/chest nodes yet.
- All other systems (map branching, rest nodes, relic offerings between fights, env effects) are **deferred** until the 10-fight backbone is verified fun and balanced.
- The 10 fights are the "test" of the methodology — they ship as a playable linear campaign while the broader infra catches up.

## Locked-in design decisions (this discussion)

- **Class composition**: 4 classes (Knight, Cleric, Rogue, Wizard), pick 2 per run. Every comp must be workable, though some comps struggle more on some fights.
- **Class identity persists**: cross-class skills are available as an escape hatch (expensive — e.g. 2× XP) but not the main progression path. A cleric is mostly a cleric all run; a rogue is mostly a rogue.
- **Tower**: static 200 HP across the 10 fights. The aspirational Monster-Train-style Pyre with per-map upgrades is **deferred**.
- **Variety mechanisms** (relics, env effects, random skill offerings): all aspirational, not in current scope. Design the 10 fights against **deterministic skill picks** first — when we layer randomness/relics on top later, we know what we're modulating from.
- **Skill progression assumption** for tuning each fight:
  - Fights 1-3: starting-kit difficulty (player has picked 0-2 extra skills)
  - Fights 4-7: player has picked 2-4 extra skills; designs can demand specific tools (AoE, ranged, sustain)
  - Fights 8-10: player has picked 7-10 extra skills; designs can be demanding because the player has tools

## Substrate-as-discovered

Don't pre-build skills/enemies before they're needed. When designing fight N, if it implicitly assumes "the priest needs AoE" or "the rogue needs mobility", that's noted as a substrate item to add. Maintain a **per-fight "blocked on substrate" list** in the fight's `LEVEL_NOTES_*.md` — fights can be designed but their Mode B verification is deferred until the substrate exists.

Substrate work already done is captured in [SIM_FINDINGS.md](../tools/sim/SIM_FINDINGS.md) and Phase 1 of the original plan (cleric Self-Or-Ally, Sword Attack, tower HP, Heal cooldown, Lowest Health First sort).

Substrate work **likely needed** but not yet built:
- Priest AoE option (mass slow? consecration?)
- Rogue mobility unlocks (Blink Away / Blink To exist; not in rogue's starting kit)
- Cleric ranged option (Holy Bolt? — for fights with unreachable archers)
- More enemy variety (we have ~6 types; for 10 fights with growing complexity we'll likely want 8-10)

## Build order: by stage, ship as we go

- **Round 1**: 3 fights on `forest_chokepoint` (existing) for difficulty positions 1-3.
- **Round 2**: 3 fights on `forest_ambush` (positions 4-6 — the existing ambush variants test close-pocket commitment + AoE thresholds). At this point sim positions 1-6 sequentially with deterministic skill-pick plans, spot cliffs.
- **Round 3**: design + build stage 3. 3 fights on it (positions 7-9). Design fight 10 as a culmination ("everything you've learned") — possibly on its own special arena.
- **Round 4**: only if rounds 1-3 surfaced "campaign mode would save us" — build run-sequence sim + batch aggregator + better diff.

Each round produces shippable content; if scope changes we stop at the last completed round.

## Verification at the set level

Per-fight: the 3-mode protocol in [LEVEL_DESIGN.md](LEVEL_DESIGN.md) (A feasibility, B robustness, C progression sanity).

Across the set: **deferred campaign-mode tooling**. Concretely we'd want:
- Run the 10-fight sequence with a configured build + per-fight skill-pick plan
- Aggregate per-fight summaries into a single "this run" report
- Compare two runs side-by-side (build A vs build B over the same sequence)
- Eventually: batch (N seeds × M comps × K fights = lots of invocations)

For now this is manual (sequential sim invocations). Build the tooling when the manual pain justifies it — probably mid Round 2.

## What this methodology is NOT

- **Not a fixed plan for 10 levels.** The arc emerges from playing each round and observing what's surprising. The methodology is "how to keep iteration honest", not "the answer for fight 7."
- **Not a commitment to randomness/branching.** Aspirational sections are explicitly aspirational. If the 10 linear fights aren't fun, randomness won't save them.
- **Not "design first, build later."** We design + build each fight together, learn from it, refine the methodology, design the next fight informed by what we learned.

## Open questions resurfacing as we build

These will come up; capture them in this section as they do (don't try to answer now):

- Win rate target for "experienced player on default 10-fight set"? (50%? 80%?)
- How harshly does difficulty ramp? Linear ramp in *what* — enemy HP? enemy count? composition variety?
- Should fight 10 always be the same "boss" or vary across runs?
- At what fight does the player feel "this is my build" — fight 3? fight 5?
