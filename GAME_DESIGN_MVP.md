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
3. **Focus Generation & Relics:** A class's identity determines how they generate **Focus** (e.g., Knights gain Focus by taking damage, Rogues by getting kills). 

### The Tower (The Aegis Core)
The heroes are escorting the **Aegis Core**—a massive magical payload that must be dragged to the epicenter of the blight (Stage 15).
If the Tower's HP reaches 0, the stage is failed (though the player can retry indefinitely). 

To prevent the Tower from making every run feel identical, it is **not** a fully complex 3rd party member. Instead, it provides a minor, synergistic foundation (similar to *Monster Train*'s Pyres):
- **Starting Chassis:** At run start, the player picks a "Core Chassis" granting it a basic, minor skill (e.g., a slow pulse heal or a minor knockback). 
- **Upgrades:** *[TBD - We need to decide exactly how/when the tower gets upgraded across the run, ensuring it remains a supporting element rather than dominating the strategy.]*

## 3. Pacing & Meta-Progression

### In-Combat Constraints
While the player's goal is to acquire skills to write wider, more complex behaviors, combat pacing is strictly gated:
1. **Focus & Cooldowns:** High-tier skills require careful resource pacing. A poorly programmed behavior might drain a hero's Focus, leaving them defenseless.
2. **Speed is Rewarded:** XP yields are tied to **Time-Bonus Multipliers** (2x XP for fast clears, 0.5x for slow clears). This creates a soft enrage and actively punishes passive, "turtle" behavior scripts.

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
2. **Accumulating Mutators:** Once unlocked via meta-progression, players will be offered a choice of 2-3 Environmental Mutators at the start of each Act (e.g. "Neverending Storm: Halve Fire damage, Double Lightning"). These mutators **accumulate** as the run progresses (Act 3 will have Act 1, 2, and 3 mutators active simultaneously), heavily warping the viable strategies for that specific run.

---

> [!WARNING]
> **Backburner Notice: Multiplayer**
> While the codebase architecture explicitly supports local and online (Nakama) multiplayer, **Multiplayer is officially on the backburner for the MVP**. All design decisions should currently optimize for a seamless single-player experience. Co-op node voting and split hero-control will be explored post-MVP.
