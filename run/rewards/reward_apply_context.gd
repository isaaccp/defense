extends RefCounted

class_name RewardApplyContext

## Abstract context passed to `RewardDef.apply_and_get_outcome` so reward
## types can drive UI sub-flows (relic recipient pick, trainer overlay)
## and trigger cosmetic feedback (HP floaters) without depending on any
## concrete UI class. RewardChoiceScreen owns the production
## implementation; tests/sim can subclass for headless contexts.

## Reveal a freshly-rolled relic to the player and await their choice of
## recipient. The implementation is expected to display `name` and `desc`
## prominently before making the party clickable.
func prompt_pick_character_for_relic(_name: String, _desc: String) -> GameplayCharacter:
	push_error("RewardApplyContext.prompt_pick_character_for_relic must be overridden")
	return null

## Open the trainer overlay (per-character skill purchases). Returns when
## the player dismisses it.
func run_trainer() -> void:
	push_error("RewardApplyContext.run_trainer must be overridden")

## Show animated "+N HP" labels for each (gc, delta) pair. Cosmetic;
## subclasses may leave the default no-op for headless contexts.
func flash_hp_floaters(_deltas: Dictionary[GameplayCharacter, int]) -> void:
	pass
