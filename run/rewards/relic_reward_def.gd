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

func apply_and_get_outcome(run_save_state: RunSaveState, ctx: RewardApplyContext) -> String:
	# Reveal the rolled relic to the player BEFORE asking for a recipient,
	# so they can choose with full info.
	var library := run_save_state.level_provider.relic_library
	var relic_def: RelicDef = library.get_relic(rolled_relic) if library else null
	var relic_display: String = relic_def.name if relic_def else String(rolled_relic)
	var relic_desc: String = relic_def.description if relic_def else ""
	var gc: GameplayCharacter = await ctx.prompt_pick_character_for_relic(
		relic_display, relic_desc
	)
	gc.add_relic(rolled_relic)
	return "%s received %s" % [gc.name, relic_display]
