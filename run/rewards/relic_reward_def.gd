@tool
extends RewardDef

class_name RelicRewardDef

## The relic this offer will grant when applied. Set by `roll()`; empty
## on the template instance stored in `LevelProvider.available_rewards`.
@export var rolled_relic: StringName = &""

func roll(rng: RandomNumberGenerator, relic_library_state: RelicLibraryState, relic_library: RelicLibrary, unlocked_skills: SkillTreeState) -> RewardDef:
	if not relic_library_state:
		push_error("RelicRewardDef.roll: no relic_library_state")
		return self
	# Filter the pool to relics whose required_actions are satisfied by
	# the run's current unlocked skill set (or are unconditional).
	var eligible: Array[StringName] = []
	for relic_name in relic_library_state.available_relics:
		var relic := relic_library.get_relic(relic_name) if relic_library else null
		if relic == null:
			continue
		if _relic_eligible(relic, unlocked_skills):
			eligible.append(relic_name)
	if eligible.is_empty():
		push_error("RelicRewardDef.roll: no eligible relics left in the library")
		return self
	var picked: StringName = eligible[rng.randi() % eligible.size()]
	# Reserve immediately so subsequent rolls don't pick the same one.
	relic_library_state.mark_relic_used(picked)
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

func apply_and_get_outcome(relic_library: RelicLibrary, gameplay_characters: Array[GameplayCharacter], ctx: RewardApplyContext) -> String:
	# Reveal the rolled relic to the player BEFORE asking for a recipient,
	# so they can choose with full info.
	var relic_def: RelicDef = relic_library.get_relic(rolled_relic) if relic_library else null
	var relic_display: String = relic_def.name if relic_def else String(rolled_relic)
	var relic_desc: String = relic_def.description if relic_def else ""
	var gc: GameplayCharacter = await ctx.prompt_pick_character_for_relic(
		relic_display, relic_desc
	)
	gc.add_relic(rolled_relic)
	return "%s received %s" % [gc.name, relic_display]
