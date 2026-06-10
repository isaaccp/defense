@tool
extends RewardDef

class_name TrainerRewardDef

func apply_and_get_outcome(_run_save_state: RunSaveState, ctx: RewardApplyContext) -> String:
	# Context drives a per-character trainer overlay (existing SkillTreeUI).
	# Returns when the player closes the trainer; no per-character outcome
	# string — the character cards update live and tell the story.
	await ctx.run_trainer()
	return "Visited a trainer."
