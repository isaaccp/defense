@tool
extends RewardDef

class_name RelicRewardDef

## The relic this offer will grant when applied. Set by `roll()`; empty
## on the template instance stored in `LevelProvider.available_rewards`.
@export var rolled_relic: StringName = &""

func roll(rng: RandomNumberGenerator, rss: RunSaveState, unlocked_skills: SkillTreeState) -> RewardDef:
	if not rss.relic_library_state:
		push_error("RelicRewardDef.roll: no relic_library_state on RunSaveState")
		return self
	var library := rss.level_provider.relic_library
	# Filter the pool to relics whose required_actions are satisfied by
	# the run's current unlocked skill set (or are unconditional).
	var eligible: Array[StringName] = []
	for relic_name in rss.relic_library_state.available_relics:
		var relic := library.get_relic(relic_name) if library else null
		if relic == null:
			continue
		if _relic_eligible(relic, unlocked_skills):
			eligible.append(relic_name)
	if eligible.is_empty():
		push_error("RelicRewardDef.roll: no eligible relics left in the library")
		return self
	var picked: StringName = eligible[rng.randi() % eligible.size()]
	# Reserve immediately so subsequent rolls don't pick the same one.
	rss.relic_library_state.mark_relic_used(picked)
	var rolled := duplicate(true) as RelicRewardDef
	rolled.rolled_relic = picked
	return rolled

static func _relic_eligible(relic: RelicDef, unlocked_skills: SkillTreeState) -> bool:
	if relic.required_actions.is_empty():
		return true
	# Missing unlocked snapshot means we can't gate — fail open rather
	# than silently exclude every gated relic.
	if not unlocked_skills:
		return true
	for action_name in relic.required_actions:
		if action_name in unlocked_skills.skills_by_name:
			return true
	return false

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
