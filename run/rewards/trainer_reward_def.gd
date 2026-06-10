@tool
extends RewardDef

class_name TrainerRewardDef

func apply_and_get_outcome(_run_save_state: RunSaveState, screen) -> String:
	# Screen drives a per-character trainer overlay (existing SkillTreeUI).
	# Returns when the player closes the trainer; no per-character outcome
	# string — the character cards update live and tell the story.
	await screen.run_trainer()
	return "Visited a trainer."
