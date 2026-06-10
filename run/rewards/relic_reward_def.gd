@tool
extends RewardDef

class_name RelicRewardDef

## The relic this offer will grant when applied. Set by `roll()`; empty
## on the template instance stored in `LevelProvider.available_rewards`.
@export var rolled_relic: StringName = &""

func roll(rng: RandomNumberGenerator, rss: RunSaveState) -> RewardDef:
	if not rss.relic_library_state:
		push_error("RelicRewardDef.roll: no relic_library_state on RunSaveState")
		return self
	var available := rss.relic_library_state.available_relics
	if available.is_empty():
		push_error("RelicRewardDef.roll: no relics left in the library")
		return self
	var idx := rng.randi() % available.size()
	var relic_name: StringName = available[idx]
	# Reserve immediately so subsequent rolls don't pick the same one.
	rss.relic_library_state.mark_relic_used(relic_name)
	var rolled := duplicate(true) as RelicRewardDef
	rolled.rolled_relic = relic_name
	return rolled

func apply_and_get_outcome(run_save_state: RunSaveState, screen) -> String:
	# Ask the screen to prompt the player for a recipient via clickable
	# character cards. Returns the chosen GameplayCharacter.
	var gc: GameplayCharacter = await screen.prompt_pick_character(
		"Choose who receives the relic"
	)
	gc.add_relic(rolled_relic)
	if screen.has_method("refresh_character_cards"):
		screen.refresh_character_cards()
	var library := run_save_state.level_provider.relic_library
	var relic_display: String = String(rolled_relic)
	if library:
		var relic := library.get_relic(rolled_relic)
		if relic:
			relic_display = relic.name
	return "%s received %s" % [gc.name, relic_display]
