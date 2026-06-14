# MVP Game Design & Campaign Shape

This document defines the high-level vision and structural "shape" of our Minimum Viable Product (MVP). For deep-dive technical definitions of these systems, refer to the linked methodology documents.

## 1. The Core Loop: The 15-Stage Arc
The campaign follows a Monster Train-style linear path of alternating combat and non-combat nodes (detailed in [`levels/CAMPAIGN_DESIGN.md`](file:///data/godot/games/defense/levels/CAMPAIGN_DESIGN.md)). 

A complete run consists of **15 Fight Stages**, divided into three Acts.
- **Act I (Stages 1–5):** Relies on the initial kit. Ends with **Boss 1** at Stage 5.
- **Act II (Stages 6–10):** Mid-game complexity. Ends with **Boss 2** at Stage 10.
- **Act III (Stages 11–15):** Late game. Demands tight mastery of acquired skills and relics. Ends with the **Final Boss** at Stage 15.

Defeating Bosses (Stages 5 and 10) grants a massive "Path" choice for each class. Because this only happens twice per run, it is a highly meaningful package choice rather than a simple stat bump. For example, a Wizard might choose between:
- *Path A:* +15 Max Focus, +0.5 Focus/sec
- *Path B:* +25% Damage, -20% Cast Time
- *Path C:* Grants a specific, game-altering Relic alongside minor stats.

## 2. The Vanguard (The Party & The Tower)

### The 2-Hero Party
A run is played with exactly **2 heroes**, chosen from the 4 available classes (Knight, Cleric, Rogue, Wizard). 
Classes possess rigid identities enforced by:
1. **Starting Kits:** The class defines the initial set of acquired skills, heavily dictating how the run begins.
2. **Skill Pools:** Skill acquisition is restricted to class-specific abilities. A Knight cannot learn Wizard spells.
3. **The Shared Focus Pool:** Instead of individual mana bars, the 2-hero party shares a single **Party Focus Pool**. 
   - **Active Generation:** Individual heroes do *not* have passive focus or focus_regen attributes. Instead, they can only generate focus *actively* via specific skills or conditional relics (e.g., Knight taking hits, Cleric healing). 
   - **Death Handling:** Because heroes only generate focus actively, a hero dying does not instantly shrink the party's Max Focus pool or cripple the baseline regen. The surviving hero simply loses the active generation the dead hero was providing.
   * **[DESIGN NOTE - Economy over Spam]:** This perfectly solves the "more skills = more spam" problem, as total party output is heavily bottlenecked by the shared pool. More importantly, it turns resource management into a cooperative programming puzzle. Players must write "budgeting" logic (e.g., *Knight casts Heavy Slam ONLY IF Party Focus > 60*, leaving a reserve for the Cleric's emergency heals) or "contextual carry" logic (e.g., *Wizard drains Focus on swarms, Rogue drains Focus on bosses*). The fun shifts from *generating* individual resources to *allocating* a shared party economy.

### The Tower (The Aegis Core)
The heroes are escorting the **Aegis Core**—a massive magical payload that must be dragged to the epicenter of the blight (Stage 15). Note that the Core is a **static defense point** during combat; it only moves narratively between stages.
If the Tower's HP reaches 0, the stage is failed (though the player can retry indefinitely). 
   * **[DESIGN NOTE - Iteration vs Attrition]:** We intentionally allow infinite retries so players can debug and tweak their AI without losing a run, while maintaining persistent HP across stages. We accept that players might retry a stage repeatedly to minimize damage taken (optimizing their HP economy), relying on the player's real-world wall-time to naturally limit extreme save-scumming behavior.

To prevent the Tower from making every run feel identical, it is **not** a fully complex 3rd party member. Instead, it provides a minor, synergistic foundation (similar to *Monster Train*'s Pyres):
- **Starting Chassis:** At run start, the player picks a "Core Chassis". Crucially, the Tower acts as the party's "battery" by providing the baseline **Max Focus and passive Focus Regen** for the entire shared pool. Different chassis offer different tradeoffs (e.g., high focus regen vs. high defense). It may also grant a basic, minor skill (e.g., a slow pulse heal).
- **Upgrades:** *[TBD - We need to decide exactly how/when the tower gets upgraded across the run, ensuring it remains a supporting element rather than dominating the strategy.]*

## 3. Pacing & Meta-Progression

### In-Combat Constraints
While the player's goal is to acquire skills to write wider, more complex behaviors, combat pacing is strictly gated:
1. **Focus & Cooldowns:** High-tier skills require careful resource pacing. A poorly programmed behavior might drain a hero's Focus, leaving them defenseless.
2. **Flat Progression:** XP and gold rewards are fixed per stage to prevent "rich get richer" snowballing or punishing defensive "turtle" behavior scripts. 
3. **Speed is for Prestige:** Fast clears are tracked locally for leaderboards. There are also meta-achievements for clearing a full run under a specific aggregate time threshold, which may unlock new content.

### Meta-Progression (The Roguelite Loop)
The MVP utilizes a **Milestone & Condition-based System** rather than a generic currency shop. This prevents players from hoarding currency to buy only "safe" power upgrades while avoiding difficulty-enhancing variety mechanics.

1. **Class Mastery (XP Milestones):** Earning XP while playing a specific class naturally progresses that class's mastery track. Hitting milestones automatically unlocks predetermined sets of advanced skills into the global pool. This ensures players learn the class's basics before being handed complex tools.
2. **Achievements (Conditions):** Game-warping mechanics, environmental mutators, and new classes are locked behind specific feats. For example:
   - *"Win any 2 runs"* $\rightarrow$ Unlocks Environmental Mutators.
   - *"Win a run with Knight + Cleric"* $\rightarrow$ Unlocks the Wizard class.

## 4. The Map Economy (Reward Nodes)
Between mandatory fights, the player must navigate the run's economy and attrition (HP loss persists across stages) by picking reward nodes. These choices dictate the *Current Kit* of the run:
1. **Trainers:** The primary engine. Spend XP to acquire new behavioral skills from the standard class pool.
2. **Campfires (Rest Nodes):** Restores party and Tower HP. *[TBD - We may add a secondary option here, like "Smithing" to upgrade existing skills, but the mechanics are undecided.]*
3. **Relic Shrines:** A free node that grants a random permanent Relic. *(Note: Distinct from the "Treasure Chests" found physically inside combat levels, which grant Gold).*
4. **Shops:** The primary Gold sink. The Merchant offers:
   - **Store-Exclusive Skills:** Unique skills that cannot be learned at standard Trainers.
   - **Relics:** Usually 2 random permanent relics.
   - **Consumables (Single-Stage Relics):** Powerful, one-time-use buffs that the player can choose to activate at the start of a difficult stage.
5. **Events:** Narrative encounters offering high-risk, high-reward choices.

## 5. Run Variety
The game guarantees that no two runs feel identical through systemic shuffling and compounding modifiers:
1. **Randomized Stages:** Every Fight Stage is randomly drawn from a pool of authored levels calibrated to the current difficulty band. 
2. **Run and Act Mutators:** Once unlocked via meta-progression, runs feature modifiers to guarantee variety.
   - **Single-Run Mutators:** At the start of a run, a global mutator may apply (e.g., "Fire is stronger, Lightning is weaker"), allowing the player to draft their party around it.
   - **Accumulating Act Mutators:** At the start of each Act, players are offered a choice between 3 negative mutators (e.g., "Monsters get +10% damage" or "Monsters get +1 Armor"). These mutators **accumulate** as the run progresses, steadily increasing the difficulty without abruptly hard-countering a specific player class element halfway through.

---

> [!WARNING]
> **Backburner Notice: Multiplayer**
> While the codebase architecture explicitly supports local and online (Nakama) multiplayer, **Multiplayer is officially on the backburner for the MVP**. All design decisions should currently optimize for a seamless single-player experience. Co-op node voting and split hero-control will be explored post-MVP.
