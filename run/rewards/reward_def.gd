@tool
extends Resource

class_name RewardDef

## Human-readable name shown on the reward stage screen.
@export var display_name: String = ""
## Short description shown alongside the outcome.
@export var description: String = ""

## Returns a per-slot instance of this reward, with any random data already
## rolled (e.g. the specific relic). Subclasses that need per-slot data
## should override and return a `duplicate(true)`. Default returns self,
## which is correct for stateless rewards (Rest, Trainer).
##
## Called once per slot at schedule generation time. Anything that should
## be reserved upfront (e.g. relic uniqueness) is mutated on `rss` here.
## `unlocked_skills` is the run-start snapshot of `SaveState.unlocked_skills`,
## available so rewards (e.g. relic) can filter based on what the party
## could plausibly use.
func roll(_rng: RandomNumberGenerator, _relic_library_state: RelicLibraryState, _relic_library: RelicLibrary, _unlocked_skills: SkillTreeState) -> RewardDef:
	return self

## Applies the reward to the run state and returns a short outcome string.
## May `await` UI signals via `ctx` for interactive rewards (Relic,
## Trainer); non-interactive rewards return synchronously.
func apply_and_get_outcome(_relic_library: RelicLibrary, _gameplay_characters: Array[GameplayCharacter], _ctx: RewardApplyContext) -> String:
	push_error("RewardDef.apply_and_get_outcome must be overridden")
	return ""
